require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << "lib"
  t.test_files = FileList['t/tc_*.rb']
  t.verbose = true
end

# TODO: task for "install" that:
#   * creates the /etc/init.d/cmk-api.$SITE script
#   * enables the script to start at boot via:
#	  chkconfig --add cmk-api.$SITE
