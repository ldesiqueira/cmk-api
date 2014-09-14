#!/usr/bin/env ruby

raise 'Unsupported version of Ruby' if RUBY_VERSION < '1.9'

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')

require 'test/unit'
 
# Unit tests for the Check_MK class
class TestCheck_MK < Test::Unit::TestCase
  require 'check_mk'

  def test_initialize
   assert_not_nil(cmk)
  end

  # Verify that there is a single folder named 'folder1'
  def test_folders
   assert_equal(['folder1'], cmk.folders)
  end

  # Get a handle to a folder
  def test_folder
   assert_not_nil(cmk.folder('folder1'))
  end

  # Verify that there is a single host named 'localhost'
  def test_hosts
   assert_equal(['localhost'], cmk.folder('folder1').hosts)
  end

  # Try to add a duplicate host
  #  FIXME: This test is broken
  def test_add_duplicate_host
   begin
     assert_nil(cmk.add_host('testduplicate', 'folder1'))
     assert_raise(ArgumentError) do
       cmk.add_host('testduplicate', 'folder1')
     end
     assert_nil(cmk.delete_host('testduplicate', 'folder1'))
   rescue
     cmk.delete_host('testduplicate', 'folder1')
   end
  end

  # Add a host and remove it
  def test_add_and_remove_host
    assert_nil(cmk.add_host('testhost', 'folder1'))
    assert_nil(cmk.delete_host('testhost', 'folder1'))
  end

  # Try to delete a nonexistent host
  def test_delete_nonexistent
    assert_raise(ArgumentError) { cmk.delete_host('does not exist', 'folder1')}
  end

  private

  # Get a fresh instance of a Wato object
  def cmk
   Check_MK.new 'http://localhost/watotest/check_mk', 'cmk-api', 'cmk-api-secret'
  end
end
