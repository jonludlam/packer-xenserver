#!/bin/bash

# Vagrant specific
date > /etc/vagrant_box_build_time

# Create vagrant user
useradd -G wheel --create-home -s /bin/bash vagrant

# Installing vagrant keys
mkdir -pm 700 /home/vagrant/.ssh
mv /tmp/vagrant.pub /home/vagrant/.ssh/authorized_keys
chmod 0600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant /home/vagrant/.ssh

# Grant sudo rights
echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
sed -i -e "s/Defaults    requiretty/#Defaults    requiretty/g" /etc/sudoers

# Set password
echo 'vagrant:vagrant' | chpasswd

for i in xapi xenopsd xenopsd-xl xenopsd-xc xcp-rrdd-plugins xcp-rrdd xcp-networkd xapi-domains squeezed firstboot forkexecd genptoken perfmon; do
  chkconfig $i off || true
  service $i stop || true
done

cat > /etc/sysconfig/network-scripts/ifcfg-eth0 <<EOF
DEVICE=eth0
BOOTPROTO=dhcp
ONBOOT=yes
EOF

chkconfig network on

rm -rf /var/lib/xcp/state.db*
rm -rf /var/lib/xcp/networkd.db*
rm -rf /var/lib/xcp/local.db

rm -rf /etc/firstboot.d/state/*

rm -rf /var/log/xensource.log*
rm -rf /var/log/daemon.log*
echo "master" > /etc/xensource/pool.conf
rm -f /etc/firstboot.d/data/host.conf
rm -f /etc/firstboot.d/05-filesystem-summarise

cat > /etc/firstboot.d/data/default-storage.conf << EOF
XSPARTITIONS='/dev/sda3'
XSTYPE='lvm'
PARTITIONS='/dev/sda3'
TYPE='lvm'
EOF

CENTOS_VERSION=`rpm -q centos-release --qf %{version}`

if [ $CENTOS_VERSION -eq '5' ]; then
   rpm -Uvh http://dl.fedoraproject.org/pub/epel/5/i386/epel-release-5-4.noarch.rpm
   yum install -y --enablerepo=base --disablerepo=citrix git-core
else 
   yum install -y --enablerepo=base --disablerepo=citrix git
fi
cd /home/vagrant

git clone git://github.com/jonludlam/vagrant-xenserver-scripts
