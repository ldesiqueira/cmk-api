#!/usr/bin/env ruby

raise 'Unsupported version of Ruby' if RUBY_VERSION != "1.9"

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')

require 'test/unit'
 
class TestRESTApi < Test::Unit::TestCase
  require 'rubygems'
  require 'rest_client'

  def setup
    @pid = Process.fork do 
      system "../bin/rest_api.rb"
    end
    sleep 5
  end

  def teardown
    kill @pid
    Process.wait
  end

  def test_top
    assert(RestClient.get('http://localhost:5006/sites'))
  end

# TODO: test these
#./bin/cmk-api-client --folder folder1 --list-hosts ; ./bin/cmk-api-client --folder folder1 --add-host=util-dev-001

end
