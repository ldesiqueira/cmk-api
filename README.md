cmk-api
=======

An unofficial REST API for check_mk

Testing
=======

See t/README for instructions on setting up a test OMD site.

Run 'rake test' to execute the testsuite.


Requirements
============

At a minimum, you should have:

 * Ruby 1.9.3 or higher
 * An OMD site running check_mk

This software is only tested with CentOS 6 and Ruby 2.0, so YMMV.


Server Installation
===================

To install the cmk-api service, perform these steps on the same
server that check_mk is running on.

  * Install the cmk-api source code:

      cd /opt
      git clone git@github.com:bronto/cmk-api.git

  * Install the required Ruby gems:

      cd cmk-api
      bundle install --path vendor/bundle
	
  * Install an init script to start/stop the service.
    Replace $SITE with the name of your OMD site,
    and $PORT with the port that you want cmk-api to listen on.

      rake install site=$SITE port=$PORT


Usage
=====

To start the server in debug mode, run this command:

  bundle exec ./bin/rackup -p 9999

Replace 9999 with the port you want to use.

(FIXME: how to run without debug mode)


Client Installation
===================

There is a command-line client to simplify the use of cmk-api from
shell scripts. To generate an RPM package of the client executable,
run:

      scl enable ruby193 'bundle exec "rake package"'


Usage
=====

REST methods
------------

The following REST methods are available:

    POST /hosts/:hostname          # Create a new host 
    PUT /hosts/:hostname/inventory # Inventory the host and add new services
    PUT /hosts/:hostname/reinventory # Redo the host inventory, automatically adding new services and dropping old services
    DELETE /hosts/:hostname        # Delete a host
    GET /hosts/:hostname           # Get a host
    PUT /activate                  # Apply changes and reload check_mk 

Autodiscovery
-------------

(NOTE: This needs to be reworked into a auto-reinventory mechanism)

The autodiscovery mechanism allows nodes to register themselves 
with check_mk after they are built. Here are the steps:

  1. Generate a secure passphrase and set it as the value of the 
     'autodiscovery_token' variable in etc/config.yaml
  1. Install the cmk-api-client RPM package during the server build process
  1. Run 'chkconfig --add cmk-api-client' at the end of the build process
  1. Update the /etc/sysconfig/cmk-api-client configuration file during 
     the Kickstart.

Bugs
====

 * After the RPM is installed, the cmk-api-client service should probably
   call "chkconfig --add" to enable itself.
