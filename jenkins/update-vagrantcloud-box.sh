#!/bin/bash

set -x

name=$1
version=$2
url=$3
apikey=$4

version=`curl https://vagrantcloud.com/api/v1/box/jonludlam/$name/versions -X POST -d version[version]="$version" -d access_token=$apikey | grep release_url | cut -d/ -f10`
curl https://vagrantcloud.com/api/v1/box/jonludlam/$name/version/$version/providers -X POST -d provider[name]='xenserver' -d provider[url]="$url" -d access_token=$apikey
curl https://vagrantcloud.com/api/v1/box/jonludlam/$name/version/$version/release -X PUT -d access_token=$apikey



