#!/usr/bin/ruby
#
# Provide a REST API for check_mk's WATO utility
#

require 'logger'
require 'sinatra'
require 'json'
require 'yaml'

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')
require 'check_mk'

def hostname
  s = params[:hostname]
  raise ArgumentError, 'illegal hostname' if s !~ /^[A-Za-z][A-Za-z0-9._-]{1,200}/
  s
end

# Read the configuration file
conffile = File.dirname(__FILE__) + '/../config.yaml'
if File.exist? conffile
  yml = YAML.load(File.open(conffile))
  @authenticate = yml['authenticate']
  @user = yml['user']
  @password = yml['password']
else
  puts "WARNING: No configuration file #{conffile}; using defaults"
  @authenticate = false
  @user = ''
  @password = ''
end

# setup logging
logdir = File.dirname(__FILE__) + '/../log'
Dir.mkdir logdir unless File.exist? logdir
logger = Logger.new(logdir + '/webrick.log', 10, 1024000)
configure do
  use Rack::CommonLogger, logger
end

if @authenticate
  use Rack::Auth::Basic, 'Restricted Area' do |username, password|
    username == @user and password == @password
  end
end

before do
  content_type :json
end

# Return a list of routes
get '/' do
  %w[hosts activate].to_json
end

# Create a new host
post '/hosts/:hostname' do
  cmk = Check_MK.new
  cmk.add_host(hostname)
  cmk.activate
  { 'content' => "Host #{hostname} created", 'status' => '0' }.to_json
end

# Delete a host
delete '/hosts/:hostname' do
  cmk = Check_MK.new
  cmk.delete_host(hostname)
  cmk.activate
  { 'content' => "Host #{hostname} deleted", 'status' => '0' }.to_json
end

# Reload the check_mk configuration
put '/activate' do
  Check_MK.new.activate
  { 'content' => "Pending changes activated", 'status' => '0' }.to_json
end
