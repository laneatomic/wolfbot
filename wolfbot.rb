#!/usr/bin/env ruby

require 'cinch'
require 'psych'
require_relative File.join(__dir__, 'lib', 'loggers', 'zcbot_logger.rb')

Dir[File.join(__dir__, 'lib', 'plugins', '*.rb')].each { |file| require file }

plugins = []

files = Dir[File.join(__dir__, 'lib', 'plugins', '*.rb')]

files.each do |file|
  plugins << Object.const_get((File.basename(file, '.rb')).capitalize)
end

config = Psych.load_file(File.join(__dir__, 'configs', 'config.yml'))

bot = Cinch::Bot.new do
  configure do |c|
    c.server = config['server']
    c.port = config['port']
    c.ssl.use = config['ssl']
    c.ssl.verify = config['verify_certs'] if config['ssl']
    c.ssl.ca_path = config['ca_path'] if config.key?('ca_path')
    c.ssl.client_cert = config['client_cert'] if config.key?('client_cert')
    c.channels = config['channels']
    c.nicks = config['nicks']
    c.password = config['password']
    c.messages_per_second = config['messages_per_second']
    c.prefix = config['prefix']
    c.plugins.plugins = plugins
  end

  on :kick do |m|
    bot.join(m.channel) if m.params[1] == bot.nick && config['rejoin']
  end
end

bot.loggers << Cinch::Logger::ZcbotLogger.new(File.open(File.join('logs', 'pisg.log'), 'a'))

bot.start
