#!/usr/bin/ruby
#
# Provide a REST API for check_mk's WATO utility
#

require 'rubygems'
require 'sinatra'
require 'json'

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')
require 'wato'

#use Rack::Auth::Basic, 'Restricted Area' do |username, password|
#  username == 'admin' and password == 'admin'
#end

def wato
  Wato.new('/omd/sites/' + params[:site])
end

# Return a list of all hosts
get '/sites/:site/hosts' do
  JSON.generate wato.hosts
end

# Return a list of all folders
get '/sites/:site/folders' do
  JSON.generate wato.folders
end

# Create a new host
post '/sites/:site/folders/:folder/:hostname' do
  #wato = Wato.new('/omd/sites/' + params[:site])
  #JSON.generate wato.hosts
end
