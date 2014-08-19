#!/usr/bin/ruby
#
# Provide a REST API for check_mk's WATO utility
#

require 'rubygems'
require 'sinatra'
require 'json'

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')
require 'check_mk'

#use Rack::Auth::Basic, 'Restricted Area' do |username, password|
#  username == 'admin' and password == 'admin'
#end

before do
  content_type :json
end

def wato
  Check_MK.new.site(params[:site])
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
get '/sites/:site/folders/:folder/hosts' do
  wato.folder(params[:folder]).hosts.to_json
end

# Create a new host
post '/sites/:site/folders/:folder/:hostname' do
  wato.folder(params[:folder]).add_host(params[:hostname])
  { 'content' => 'Host created', 'status' => '0' }.to_json
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
