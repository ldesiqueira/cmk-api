#!/usr/bin/env ruby
#
# Provide a REST API for check_mk's WATO utility
#

raise 'Unsupported Ruby version' unless RUBY_VERSION >= "1.9"

require 'sinatra/base'

class CmkAPI < Sinatra::Base 
  require 'logger'
  require 'json'
  require 'resolv'
  require 'thread'
  require 'yaml'
  
  $LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')
  require 'check_mk'
  
  def hostname
    s = params[:hostname]
    raise ArgumentError, 'illegal hostname' if s !~ /^[A-Za-z][A-Za-z0-9\._-]{1,200}/
    s
  end

  def cmk
    @@cmk
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
    $autodiscovery_token = yml['autodiscovery_token']
  else
    raise "No configuration file: #{conffile}"
  end

  # setup logging
  if ENV['CMKAPI_LOGDIR']
    logdir = ENV['CMKAPI_LOGDIR']
    logger = Logger.new(logdir + '/cmk-api.log', 10, 1024000)
  else
    logger = Logger.new($stdout)
  end
  configure :production, :development do
    use Rack::CommonLogger, logger
    enable :logging
  end
  
  @@cmk = Check_MK.new(
         uri: $uri,
         user: $user,
         password: $password,
         logger: logger)
  
  helpers do
    def protected!
      return if authorized?
      headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
      halt 401, "Not authorized\n"
    end

    def authorized?
      @auth ||=  Rack::Auth::Basic::Request.new(request.env)
      return false unless @auth.provided? and @auth.basic? and @auth.credentials

      # Allow the administrator to access all routes
      return true if @auth.credentials == [$user, $password]

      # Allow limited access for auto-discovery
      unless @auth.credentials == ['autodiscovery', $autodiscovery_token]
        logger.warn 'autodiscovery_token mismatch'
        return false
      end

      # Verify that the originating IP address matches the hostname
      host = request.path_info.sub(/^\/hosts\//, '').sub(/\/.*/, '')
      begin
        expected_ip = Resolv.new.getaddress(host)
        if expected_ip != request.ip
          logger.warn "name/IP address mismatch; expected #{expected_ip} but got #{request.ip}"
          return false
        end
      rescue Resolv::ResolvError => e
        logger.warn e
        return false
      end

      return true
    end
  end
  
  before do
    protected! if $authenticate
    content_type :json
  end
  
  # Return a list of routes
  get '/' do
    %w[hosts activate].to_json
  end
  
  # Return a list of all hosts
  get '/hosts' do
    { 'results' => cmk.hosts, 'status' => '0' }.to_json
  end
  
  # Create a new host
  post '/hosts/:hostname' do
    cmk.add_host(hostname)
    { 'content' => "Host #{hostname} created", 'status' => '0' }.to_json
  end
  
  # Delete a host
  delete '/hosts/:hostname' do
    cmk.delete_host(hostname)
    { 'content' => "Host #{hostname} deleted", 'status' => '0' }.to_json
  end
  
  # Inventory a host
  put '/hosts/:hostname/inventory' do
    cmk.inventory_host(hostname)
    { 'content' => "Host #{hostname} inventoried", 'status' => '0' }.to_json
  end
      
  # Reload the check_mk configuration
  put '/activate' do
    #DEADWOOD:
    #activation_mutex.synchronize do
    #  activation_requested = true
    #  activation_cond.signal
    #end
    cmk.activate
    { 'content' => "Pending changes activated", 'status' => '0' }.to_json
  end
  
  # start the server if ruby file executed directly
  run! if app_file == $0
end
