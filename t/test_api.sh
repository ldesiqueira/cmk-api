#!/bin/sh

# FIXME: rewrite in ruby, use the rest-client gem and Test::Unit

curl -XPOST -H "Content-Type: application/json" -d '{}' http://localhost:4567/hosts/testhost3

curl -XDELETE -H "Content-Type: application/json" -d '{}' http://localhost:4567/hosts/testhost3

curl -XPUT -H 'Content-Length: 0' http://localhost:4567/activate

