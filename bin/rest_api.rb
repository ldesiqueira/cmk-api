#!/usr/bin/ruby
#
# Provide a REST API for check_mk's WATO utility
#

require 'rubygems'
require 'sinatra'
require 'json'
require 'yaml'

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')
require 'check_mk'

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

if @authenticate
  use Rack::Auth::Basic, 'Restricted Area' do |username, password|
    username == @user and password == @password
  end
end

before do
  content_type :json
end

def wato
  Check_MK.new.site(params[:site])
end

# Return a list of routes
get '/' do
  %w[sites].to_json
end

# Return a list of all hosts
get '/sites' do
  Check_MK.new.sites.to_json
end

# Return a list of all routes related to /sites/:site
get '/sites/:site' do
  site = Check_MK.new.site(params[:site])
  JSON.pretty_generate(
  { 
	'hosts' => site.hosts,
        'folders' => site.folders,
  })
end

# Return a list of all hosts
get '/sites/:site/hosts' do
  JSON.generate wato.hosts
end

# Return a list of all folders
get '/sites/:site/folders' do
  wato.folders.to_json
end

# Return a list of all hosts in a folder
get '/sites/:site/folders/:folder' do
  folder = Check_MK.new.site(params[:site]).folder(params[:folder])
  JSON.pretty_generate(
  {
	'name' => params[:folder],
        'hosts' => folder.hosts,
  })
end

# Create a new host
post '/sites/:site/folders/:folder/hosts/:hostname' do
  hostname = params[:hostname]
  raise ArgumentError, 'illegal hostname' if hostname !~ /^[A-Za-z][A-Za-z0-9._-]{1,200}/
  wato.folder(params[:folder]).add_host(hostname)
  { 'content' => "Host #{hostname} created", 'status' => '0' }.to_json
end

# Delete a host
delete '/sites/:site/folders/:folder/:hostname' do
  wato.folder(params[:folder]).delete_host(params[:hostname])
  { 'content' => 'Host deleted', 'status' => '0' }.to_json
end

# Reload the check_mk configuration
put '/sites/:site/:action' do
  content = 'error -- not implemented'
  status = 255
  case params[:action]
  when 'reload'
    content = `cmk -O`
    status = $?
  when 'restart'
    content = `cmk -R`
    status = $?
  else
    raise ArgumentError, 'invalid action'
  end
#  content_type :json
  { 'content' => content, 'status' => status.to_s }.to_json
end
