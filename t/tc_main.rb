#!/usr/bin/ruby

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')

require 'test/unit'
 
class TestMain < Test::Unit::TestCase
  require 'check_mk'
  require 'yaml'

#DEADWOOD:
#  def setup
#    conffile = File.dirname(__FILE__) + '/config.yaml'
#    if File.exist? conffile
#      yml = YAML.load(File.open(conffile))
#      @ignore_sites = yml['ignore_sites']
#    else
#      # Sites which should be ignored during testing
#      @ignore_sites = []
#    end
#  end

  def test_initialize
   assert_not_nil(cmk)
  end

  # Add a host
  def test_add_and_delete_host
    hostname = `hostname`.chomp
    assert_nil(cmk.add_host(hostname))
    assert_nil(cmk.delete_host(hostname))
    assert_nil(cmk.activate)
  end

  private

  # Get a fresh instance of a Check_MK object
  def cmk
   Check_MK.new
  end
end
