require 'cinch'
require 'mongo'

# Hello plugin
class Admin
  include Cinch::Plugin
  include Mongo

  listen_to :join

  set :prefix, /^:/

  match /opup$/, method: :op_up
  match /opdown$/, method: :op_down
  match /kick (.+)$/, method: :kick
  match /ban (.+)$/, method: :ban
  match /unban (.+)$/, method: :unban
  match /listbans$/, method: :list_bans
  match /help$/, method: :help
  match /warn (.+)$/, method: :warn

  # Non-Admin commands (reporting players, etc.)
  match /report (.+)$/, method: :report
  match /stats$/, method: :stats
  # Mess around with people who try to vote for wolfbot
  match /^!(v|vo|vot|vote)\swolfbot$/i, method: :vote, use_prefix: false

  # Owner-only commands
  match /add_admin (.+)$/, method: :add_admin
  match /del_admin (.+)$/, method: :del_admin
  match /enforce_opdown$/, method: :enforce_opdown
  match /restart$/, method: :restart

  def initialize(*args)
    super

    @config = Psych.load_file(File.join(__dir__, '..', '..', 'configs', 'admin.yml'))
    @game_channel = @config['game_channel']
    @admin_channel = @config['admin_channel']
    @reporters = []

    @db = MongoClient.new(@config['db_host'], @config['db_port']).db('admin_plugin')
  end

  def report(m, target)
    if @reporters.include?(m.user)
      m.reply "#{m.user}: Please wait 30 seconds between reports."
      return
    end

    target_exists = false
    Channel(@game_channel).users.each do |user, modes|
      target_exists = true if user == User(target)
    end

    m.reply "#{m.user.nick}: Reported #{target} for rules violations. Please see \#werewolfops."
    Channel(@admin_channel).send "#{m.user.nick} has reported #{target} for rules violations. Please investigate.", notice = true
    @reporters << m.user
    Timer(30) do
      @reporters.delete(m.user)
    end
  end

  def stats(m)
    m.reply "Stats can be found at #{@config['stats_url']}"
  end

  def vote(m)
    m.reply "I am sorry, #{m.user.nick}. As per the First Law of Robotics, I am unable to harm villagers. Therefore it cannot be me." if m.channel == Channel(@game_channel)
  end

  def listen(m)
    # Weirdness: replies when self-joining. Added nick check to not trigger itself.
    return unless m.channel == Channel(@game_channel) && @config['greet'] && m.user.nick != bot.nick
    
    if @config['greet_moderated_only']
      m.reply "#{m.user.nick}: #{@config['greeting']}" if m.channel.moderated?
    else
      m.reply "#{m.user.nick}: #{@config['greeting']}"
    end
  end

  def restart(m)
    return unless owner?(m)
    bot.quit("Restart forced by #{m.user.nick}")
    pid = Process.exec 'ruby wolfbot.rb'

    Process.detach pid
  end

  def op_up(m)
    Channel(@game_channel).mode("+h #{m.user.nick}") if halfop?(m) && !admin?(m)
    Channel(@game_channel).op(m.user) if admin?(m)
  end

  def op_down(m)
    Channel(@game_channel).mode("-h #{m.user.nick}") if halfop?(m) && !admin?(m)
    Channel(@game_channel).deop(m.user) if admin?(m)
  end

  def warn(m, args)
    target, reason = args.split(/ /, 2)
    reason ||= 'You are being warned for rules violations. Continue and we will take further action.'
    reason += " - #{m.user.nick}"
    return unless halfop?(m) || !Channel(@game_channel).users.key?(User(target))
    Channel(@game_channel).send("#{target}: #{reason}")
  end

  def kick(m, args)
    target, reason = args.split(/ /, 2)
    reason ||= 'Kicked by the bot.'
    Channel(@game_channel).kick(target, reason) if admin?(m)
  end

  def ban(m, args)
    return unless halfop?(m)
    target, hostmask = args.split(/ /, 2)
    hostmask ||= User(target).host
    banmask = "*#{target}*!*@#{hostmask}"
    Channel(@game_channel).ban("#{banmask}")
    kick(m, "#{target} Banned by the bot.")
  end

  def unban(m, banmask)
    return unless halfop?(m)
    if banmask.nil?
      m.reply "#{banmask} can not be empty."
      return
    end
    Channel(@game_channel).unban(banmask)
  end

  def list_bans(m)
    return unless halfop?(m)
    Channel(@game_channel).bans.each do |ban|
      m.user.send ban.mask
    end
  end

  def enforce_opdown(m)
    return unless owner?(m)
    users = Channel(@game_channel).users
    ops = []
    half_ops = []
    users.each do |user, user_array|
      ops << user if user_array.include?('o') && user != bot.nick && user.nick.downcase != 'werewolf'
      half_ops << user if user_array.include?('h') && user != bot.nick && user.nick.downcase != 'werewolf'
    end
    return if ops.empty? && half_ops.empty?
    puts 'Made it here.'
    o = 'o' * ops.length unless ops.empty?
    h = 'h' * half_ops.length unless half_ops.empty?
    Channel(@game_channel).mode("-#{o} #{ops.join(' ')}") unless ops.empty?
    Channel(@game_channel).mode("-#{h} #{half_ops.join(' ')}") unless half_ops.empty?
  end

  def help(m)
    return unless halfop?(m)
    m.user.send 'Available commands are:'
    m.user.send ":warn <username>[ <reason>] - This will send a message signed with your nick to #{@game_channel} warning the specified user."
    m.user.send ":kick <username>[ <reason>] - Kicks the specified user from #{@game_channel}."
    m.user.send ":ban <username>[ <hostmask>] - Bans the specified user from #{@game_channel}. Defaults to target's full hostmask if none specified."
    m.user.send ':unban <banmask> - Unbans the banmask specified in :listbans.'
    m.user.send ":listbans - See all currently banned banmasks in #{@game_channel}."
    m.user.send ":opup - Give yourself %/@ (halfop/ops) in #{@game_channel} - To be used if bot can't handle the issue."
    m.user.send ":opdown - Remove your %/@ (halfop/ops) in #{@game_channel}"
    m.user.send 'Available owner commands are:' if owner?(m)
    m.user.send ":enforce_opdown - Remove @ (ops) and % (halfops) from all users other than the bots in #{@game_channel}." if owner?(m)
    m.user.send ':restart - Restart the bot.' if owner?(m)
  end

  private

  # Access Levels checking
  def admin?(m)
    return Channel(@admin_channel).opped?(m.user) || owner?(m)
  end

  def owner?(m)
    return Channel(@admin_channel).admins.include?(m.user) || Channel(@admin_channel).owners.include?(m.user)
  end

  def halfop?(m)
    return Channel(@admin_channel).half_opped?(m.user) || admin?(m) || owner?(m)
  end

  def insert_warning(nickname, admin)
    coll = @db.collection('warnings')
    doc = {
      admin: admin,
      last_warned: Time.now.getutc.to_i,
      "$inc" => {warnings: 1}
    }

    coll.update({nickname: nickname}, doc, upsert: true)
  end

  def insert_report(nickname, reporter)
    coll = @db.collection('reports')
end
