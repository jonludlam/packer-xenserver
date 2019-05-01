#!/bin/bash

set -x
set -e

branch=$1
server=$2
password=$3
apikey=$4
artifactory=$5
isoname=$6
bvtuser=$7
bvtpass=$8
buildoverride=$9

export PATH=/local/bigdisc/packer-bin:$PATH

boxbasedir=/usr/local/builds/vagrant
resultdir=/local/bigdisc/vagrant

escapedbranch=`echo $branch | sed sx/x%252Fxg`
vagrantboxname=`echo $branch | sed sx/x-xg`

JVERSION=`curl "https://$bvtuser:$bvtpass@ratchet.do.citrite.net/job/xenserver-build/job/$escapedbranch/api/json" | jq .lastSuccessfulBuild.number`

if [ "x"$buildoverride != "x" ]; then
	VERSION=$buildoverride
else
	VERSION=$JVERSION
fi

exists=`jenkins/vagrantcloud-box-exists.sh $vagrantboxname 0.0.$VERSION $apikey`

if [ $exists == "yes" ]; then
   exit 0
fi

echo branch=$branch
echo VERSION=$VERSION
# Make a tmp dir to construct the box
boxdir=$boxbasedir/tmp-$vagrantboxname

xva=$vagrantboxname.$VERSION.xva
fullxva=$vagrantboxname.full.$VERSION.xva
boxfile=$vagrantboxname.$VERSION.box

rm -rf $boxdir
mkdir -p $boxdir
packer build -only=xenserver-iso -var "artifactory=$artifactory" -var "branch=$branch" -var "xshost=$server" -var "xspassword=$password" -var "outputdir=$boxdir" -var "version=$VERSION" -var "isoname=$isoname" internal/template-dev.json
rm -rf packer_cache/*
mkdir -p $resultdir/$vagrantboxname
mv $boxdir/*.xva $resultdir/$vagrantboxname/$xva
packer build -only=xenserver-iso -var "artifactory=$artifactory" -var "branch=$branch" -var "xshost=$server" -var "xspassword=$password" -var "outputdir=$boxdir" -var "version=$VERSION" -var "isoname=$isoname" internal/template.json
rm -rf packer_cache/*
mv $boxdir/*.xva $resultdir/$vagrantboxname/$fullxva

echo "{\"provider\": \"xenserver\"}" > $boxdir/metadata.json
cat > $boxdir/Vagrantfile << EOF
Vagrant.configure(2) do |config|
  config.vm.provider :xenserver do |xs|
    xs.xva_url = "http://xen-git.uk.xensource.com/vagrant/$vagrantboxname/$xva"
  end
end
EOF
cd $boxdir
tar zcf $resultdir/$vagrantboxname/$boxfile .
cd -

rm -rf $boxdir

pushd $resultdir/$vagrantboxname
(ls -t|head -n 5;ls)|sort|uniq -u|xargs rm -f
popd

SHA=`sha1sum $resultdir/$vagrantboxname/$boxfile | cut -d\  -f1`

cat > $resultdir/$vagrantboxname/$vagrantboxname.json <<EOF
{
  "name": "xenserver/$vagrantboxname",
  "description": "This box contains XenServer installed from branch $branch",
  "versions": [{
    "version": "0.0.$VERSION",
    "providers": [{
      "name": "xenserver",
      "url": "http://xen-git.uk.xensource.com/vagrant/$vagrantboxname/$boxfile",
      "checksum_type": "sha1",
      "checksum": "$SHA"
    }]
  }]
}
EOF

jenkins/create-vagrantcloud-box.sh $vagrantboxname $apikey
jenkins/update-vagrantcloud-box.sh $vagrantboxname 0.0.$VERSION http://xen-git.uk.xensource.com/vagrant/$vagrantboxname/$boxfile $apikey


