#!/usr/bin/env ruby

raise 'Unsupported version of Ruby' if RUBY_VERSION != "1.9"

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')

require 'test/unit'
 
class TestCLI < Test::Unit::TestCase

# TODO: test these
#./bin/cmk-api-client --folder folder1 --list-hosts ; 
#./bin/cmk-api-client --folder folder1 --add-host=testcli1
#./bin/cmk-api-client --folder folder1 --delete-host=testcli1

end
