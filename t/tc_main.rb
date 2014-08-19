#!/usr/bin/ruby

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')

require 'test/unit'
 
class TestMain < Test::Unit::TestCase
  require 'check_mk'
  require 'yaml'

  def setup
    conffile = File.dirname(__FILE__) + '/config.yaml'
    if File.exist? conffile
      yml = YAML.load(File.open(conffile))
      @ignore_sites = yml['ignore_sites']
    else
      # Sites which should be ignored during testing
      @ignore_sites = []
    end
  end

  def test_initialize
   assert_not_nil(cmk)
  end

  # Get a list of all sites
  def test_sites
    sites = @ignore_sites.dup
    sites.push 'watotest'
    assert_equal(sites.sort, cmk.sites)
  end

  # Get a handle to a site
  def test_site
    assert_not_nil(cmk.site('watotest'))
  end

  private

  # Get a fresh instance of a Check_MK object
  def cmk
   Check_MK.new
  end
end
