#!/usr/bin/ruby

$LOAD_PATH.unshift '../lib'

require 'test/unit'
 
class TestWato < Test::Unit::TestCase
  require 'check_mk'

  def test_initialize
   assert_not_nil(wato)
  end

  # Verify that there is a single folder named 'folder1'
  def test_folders
   assert_equal(['folder1'], wato.folders)
  end

  # Get a handle to a folder
  def test_folder
   assert_not_nil(wato.folder('folder1'))
  end

  # Verify that there is a single host named 'localhost'
  def test_hosts
   assert_equal(['localhost'], wato.hosts)
  end

  # Try to add a duplicate host
  #  FIXME: This test is broken
  def test_add_duplicate_host
   begin
     assert_nil(wato.folder('folder1').add_host('testduplicate'))
     assert_raise(ArgumentError) do
       wato.folder('folder1').add_host('testduplicate')
     end
     assert_nil(wato.folder('folder1').delete_host('testduplicate'))
   rescue
     wato.folder('folder1').delete_host('testduplicate')
   end
  end

  # Add a host and remove it
  def test_add_and_remove_host
    assert_nil(wato.folder('folder1').add_host('testhost'))
    assert_nil(wato.folder('folder1').delete_host('testhost'))
  end

  # Try to delete a nonexistent host
  def test_delete_nonexistent
    assert_raise(ArgumentError) { wato.folder('folder1').delete_host('does not exist')}
  end

  private

  # Get a fresh instance of a Wato object
  def wato
   Check_MK.new.site('watotest')
  end
end
