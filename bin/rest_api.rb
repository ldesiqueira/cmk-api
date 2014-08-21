#!/usr/bin/env ruby
#
# Provide a REST API for check_mk's WATO utility
#

raise 'Unsupported Ruby version' unless RUBY_VERSION >= "1.9"

require 'sinatra/base'

class CmkAPI < Sinatra::Base 
  require 'logger'
  require 'json'
  require 'yaml'
  
  $LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')
  require 'check_mk'
  
  def hostname
    s = params[:hostname]
    raise ArgumentError, 'illegal hostname' if s !~ /^[A-Za-z][A-Za-z0-9._-]{1,200}/
    s
  end

  def cmk
    Check_MK.new($uri, $user, $password)
  end
  
  # Read the configuration file
  confdir = File.realpath(File.dirname(__FILE__) + '/../etc')
  conffile = confdir + '/config.yaml'
  if File.exist? conffile
    yml = YAML.load(File.open(conffile))
    $uri = yml['uri']
    $authenticate = yml['authenticate']
    $user = yml['user']
    $password = yml['password']
  else
    raise "No configuration file: #{conffile}"
  end
  
  # setup logging (assuming we are running under OMD)
  logdir = ENV['HOME'] + '/var/log'
  logger = Logger.new(logdir + '/cmk-api.log', 10, 1024000)
  configure do
    use Rack::CommonLogger, logger
  end
  
  if $authenticate
    use Rack::Auth::Basic, 'Restricted Area' do |username, password|
      username == $user and password == $password
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
    cmk.add_host(hostname)
    cmk.activate
    cmk.inventory_host(hostname)
    { 'content' => "Host #{hostname} created", 'status' => '0' }.to_json
  end
  
  # Delete a host
  delete '/hosts/:hostname' do
    cmk.delete_host(hostname)
    cmk.activate
    { 'content' => "Host #{hostname} deleted", 'status' => '0' }.to_json
  end
  
  # Reload the check_mk configuration
  put '/activate' do
    cmk.activate
    { 'content' => "Pending changes activated", 'status' => '0' }.to_json
  end
  
  # start the server if ruby file executed directly
  run! if app_file == $0
end
