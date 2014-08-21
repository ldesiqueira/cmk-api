cmk-api
=======

check_mk REST API

Testing
=======

See t/README for instructions on setting up a test OMD site.

Run 'rake test' to execute the testsuite.


Installation
============

sudo yum install -y ruby193-rubygem-minitest ruby193-rubygem-sinatra \
  ruby193-ruby-devel gcc-c++
sudo scl enable ruby193 'gem install rest-client'
sudo scl enable ruby193 'gem install thin'

TODO
----

Use the built-in automation support instead of hacking up hosts.mk; see
http://mathias-kettner.de/checkmk_multisite_automation.html

Example of creating a host:

    http://util-dev-001.brontolabs.local/watotest/check_mk/wato.py?
    filled_in=edithost
    &_transid=-1
    &host=util-dev-001
    &contactgroups_use=on
    &attr_alias=
    &attr_ipaddress=
    &parents_0=
    &attr_tag_agent=cmk-agent%7Ctcp
    &attr_tag_criticality=prod
    &attr_tag_networking=lan
    &save=Save+%26+Finish
    &folder=folder1
    &mode=newhost

Example of deleting a host:

http://util-dev-001.brontolabs.local/watotest/check_mk/wato.py?mode=folder&_delete_host=util-dev-001&_transid=1408577873/2868306339&folder=folder1&do_confirm=yes
