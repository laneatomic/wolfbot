require 'sinatra'
require 'mongo'
require 'psych'

@config = Psych.load_file(File.join(__dir__, '..', '..', '..', 'configs', 'admin.yml'))
@db = Mongo::Client.new(["#{@config['db_host']}:#{@config['db_port']}"], database: 'admin_plugin')
#admin_sinatra.rb

get '/' do
end

get '/bans' do
end

get '/warnings' do
end

get '/reports' do
  get_reports.each do |report|
    "#{report}"
  end
end

def get_bans
  @db[:bans].find.sort(nickname: 1)
end

def get_warnings
  @db[:warnings].find.sort(nickname: 1)
end

def get_reports
  @db[:reports].find.sort(nickname: 1)
end
