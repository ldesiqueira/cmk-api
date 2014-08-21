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

task :install do
  site = ENV['site'] or raise 'site is required'
  port = ENV['port'] or raise 'port is required'

  # Create the init script
  rcfile = "/etc/init.d/cmk-api.#{site}"
  erb = ERB.new(File.read('./templates/rc.erb'))
  puts "Creating #{rcfile}.."
  File.open(outfile, 'w') { |f| f.write(erb.result) }
  system "chkconfig --add cmk-api.#{site}"

  # Create the sysconfig file
  scfile = "/etc/sysconfig/cmk-api.#{site}"
  puts "Creating #{scfile}.."
  erb = ERB.new(File.read('./templates/sysconfig.erb'))
  File.open(outfile, 'w') { |f| f.write(erb.result) }

  system "service cmk-api.#{site} start"
end
