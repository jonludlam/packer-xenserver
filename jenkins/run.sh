#!/bin/bash

set -x
set -e

branch=$1
server=$2
password=$3
apikey=$4

export PATH=/local/bigdisc/packer-bin:$PATH

boxbasedir=/usr/local/builds/vagrant
resultdir=/local/bigdisc/vagrant
VERSION=`readlink /usr/groups/build/$branch/latest`

# Make a tmp dir to construct the box
boxdir=$boxbasedir/tmp-$branch

rm -rf $boxdir
mkdir -p $boxdir
packer build -only=xenserver-iso -var "branch=$branch" -var "xshost=$server" -var "xspassword=$password" -var "outputdir=$boxdir" -var "version=$VERSION" template.json
rm -rf packer_cache/*
mv $boxdir/*.vhd $boxdir/box.vhd
echo "{\"provider\": \"xenserver\"}" > $boxdir/metadata.json
cd $boxdir
mkdir -p $resultdir/$branch
tar zcf $resultdir/$branch/$branch.$VERSION.box .
cd -

rm -rf $boxdir

pushd $resultdir/$branch
(ls -t|head -n 2;ls)|sort|uniq -u|xargs rm -f
popd

SHA=`sha1sum $resultdir/$branch/$branch.$VERSION.box | cut -d\  -f1`

cat > $resultdir/$branch/$branch.json <<EOF
{
  "name": "xenserver/$branch",
  "description": "This box contains XenServer installed from branch $branch",
  "versions": [{
    "version": "0.0.$VERSION",
    "providers": [{
      "name": "xenserver",
      "url": "http://xen-git.uk.xensource.com/vagrant/$branch/$branch.$VERSION.box",
      "checksum_type": "sha1",
      "checksum": "$SHA"
    }]
  }]
}
EOF

boxname=xs-$branch

echo boxname=$boxname


jenkins/create-vagrantcloud-box.sh $boxname $apikey
jenkins/update-vagrantcloud-box.sh $boxname 0.0.$VERSION http://xen-git.uk.xensource.com/vagrant/$branch/$branch.$VERSION.box $apikey


