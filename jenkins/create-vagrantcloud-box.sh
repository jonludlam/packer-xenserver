#!/bin/bash
set -x

name=$1
apikey=$2

curl https://vagrantcloud.com/api/v1/boxes -X POST -d box[name]="$name" -d box[is_private]=false -d access_token=$apikey

