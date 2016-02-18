#!/bin/bash

mount /dev/sda1 /mnt

ln -s ../init.d/veryfirstboot /mnt/etc/rc3.d/S03veryfirstboot

# Put some things into the chroot
wget --no-check-certificate 'https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub' -O /tmp/vagrant.pub
cp /tmp/chroot_script.sh /mnt/tmp/
cp /tmp/vagrant.pub /mnt/tmp/

# Now run a script within the chroot
chmod 755 /mnt/tmp/chroot_script.sh
cp /tmp/veryfirstboot /mnt/etc/init.d/veryfirstboot
chmod 755 /mnt/etc/init.d/veryfirstboot
ln -s ../init.d/veryfirstboot /mnt/etc/rc3.d/S03veryfirstboot
chroot /mnt /tmp/chroot_script.sh

echo "UseDNS no" >> /mnt/etc/ssh/sshd_config  # Disable DNS lookups
echo "GSSAPIAuthentication no" >> /mnt/etc/ssh/sshd_config # Disable negotation of slow GSSAPI

# Clean up
umount /mnt

