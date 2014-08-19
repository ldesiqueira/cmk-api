#!/bin/sh

# FIXME: rewrite in ruby, use the rest-client gem and Test::Unit

curl -XPUT -H 'Content-Length: 0' http://localhost:4567/sites/watotest/restart

curl -XPOST -H "Content-Type: application/json" -d '{}' http://localhost:4567/sites/watotest/folders/folder1/testhost3

curl -XDELETE -H "Content-Type: application/json" -d '{}' http://localhost:4567/sites/watotest/folders/folder1/testhost3

curl http://localhost:4567/sites/watotest/folders/folder1/hosts
