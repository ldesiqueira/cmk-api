cmk-api
=======

An unofficial REST API for check_mk

Testing
=======

See t/README for instructions on setting up a test OMD site.

Run 'rake test' to execute the testsuite.

Requirements
============

 * CentOS 6
 * Ruby 1.9.3 via the SCL mechanism
 * OMD

Installation
============

  	# Dependencies
	sudo yum install -y ruby193-rubygem-minitest ruby193-rubygem-sinatra \
  		ruby193-ruby-devel gcc-c++ rpm-build

	cd /opt
	git clone git@github.com:bronto/cmk-api.git
	cd cmk-api
	scl enable ruby193 'bundle install --path ./gems'
	
	# Replace $SITE and $PORT with the appropriate values
  	sudo scl enable ruby193 'rake install site=$SITE port=$PORT'

        scl enable ruby193 'bundle exec "rake package"'

Usage
=====

Autodiscovery
-------------

The autodiscovery mechanism allows nodes to register themselves with check_mk after
they are built. Here are the steps:

  1. Generate a secure passphrase and set it as the value of the 'autodiscovery_token' 
     variable in etc/config.yaml
  1. Install the cmk-api-client RPM package during the server build process
  1. Run 'chkconfig --add cmk-api-client' at the end of the build process
  1. Update the /etc/sysconfig/cmk-api-client configuration file during the Kickstart.
