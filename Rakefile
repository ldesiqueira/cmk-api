$VERSION = '0.1.1'

require 'fileutils'
require 'rake/testtask'
require 'erb'

Rake::TestTask.new do |t|
  t.libs << "lib"
  t.test_files = FileList['t/tc_*.rb']
  t.verbose = true
end

task :package do
  pkgroot = './pkg'
  [pkgroot, "#{pkgroot}/etc", "#{pkgroot}/etc/init.d"].each { |d| Dir.mkdir d }
  cp('bin/rc.cmk-api-client', "#{pkgroot}/etc/init.d/cmk-api-client")
  chmod(0755, "#{pkgroot}/etc/init.d/cmk-api-client")

  mkdir "#{pkgroot}/etc/sysconfig"
  cp('examples/sysconfig.cmk-api-client', "#{pkgroot}/etc/sysconfig/cmk-api-client")
  chmod(0700, "#{pkgroot}/etc/sysconfig/cmk-api-client")
  FileUtils.mkdir_p "#{pkgroot}/var/lib/cmk-api-client"
  chmod(0700, "#{pkgroot}/var/lib/cmk-api-client")
  system "fpm -s dir -t rpm -n cmk-api-client -v #{$VERSION} -a noarch --epoch 1 --config-files /etc/sysconfig/cmk-api-client -C ./pkg ."
  system "rm -rf ./pkg"
end

task :install do
  @site = ENV['site'] or raise 'site is required'
  @port = ENV['port'] or raise 'port is required'

  # Create the init script
  rcfile = "/etc/init.d/cmk-api.#{@site}"
  erb = ERB.new(File.read('./templates/rc.erb'))
  puts "Creating #{rcfile}.."
  File.open(rcfile, 'w') { |f| f.write(erb.result) }
  File.chmod 0755, rcfile
  system "chkconfig --add cmk-api.#{@site}"

  # Create the sysconfig file
  scfile = "/etc/sysconfig/cmk-api.#{@site}"
  puts "Creating #{scfile}.."
  erb = ERB.new(File.read('./templates/sysconfig.erb'))
  File.open(scfile, 'w') { |f| f.write(erb.result) }

  system "service cmk-api.#{@site} start"
end
