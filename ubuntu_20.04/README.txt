Steps for creating a simple Debian 10 (buster) image for the Shield96 board

- create uSD image with the following commands
    $ sudo parted /dev/sdX mklabel msdos
    $ sudo parted /dev/sdX mkpart primary fat32 8s 42605s -s
    $ sudo parted /dev/sdX mkpart primary ext4 42608s 9584649s -s
    $ sudo parted /dev/sdX mkpart primary linux-swap 9584650s 10108937s -s
    $ sudo parted /dev/sdX set 1 boot on

    $ sudo mkfs.msdos /dev/sdX1 -n boot
    $ sudo mkfs.ext4 /dev/sdX2 -L root

- in this folder execute:
    $ sudo apt-get install multistrap
    $ sudo ./build.sh
  this will create a minimal Debian 10 rootfs

- re-insert uSD card to make Linux mount 'boot' and 'root' partitions

- execute this in current folder (copy over all files):
    $ sudo cp rootfs/* /media/<user>/root/ -a
    $ sudo chown root: rootfs.add/ -R

- copy files and symlinks from rootfs.add/ to uSD card
    $ sudo cp rootfs.add/* /media/<user>/root/ -a

- remove "getty-static.service" on uSD card:
    $ sudo rm /media/<user>/root/lib/systemd/system/getty.target.wants/getty-static.service

- create a standard Yocto BSP image by doing a full Yocto build

- populate 'boot' partition
  In Yocto build folder execute:
    $ cp -L tmp/deploy/images/sama5d27-sd96/BOOT.BIN /media/<user>/boot/
    $ cp -L tmp/deploy/images/sama5d27-sd96/u-boot.bin /media/<user>/boot/
    $ cp -L tmp/deploy/images/sama5d27-sd96/uboot.env /media/<user>/boot/
    $ cp -L tmp/deploy/images/sama5d27-sd96/sama5d27_sd96.itb /media/<user>/boot/

- unmount uSD card (and sync)

- power up Shield96 with new uSD card. Ethernet connection will need a DHCP server.

- when Shield96 finishes booting press Enter and execute the following:
    # mount -t proc nodev /proc
    # PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin dpkg --configure -a

- during configuration select TimeZone and answer "no" when asked if /bin/dash should replace /bin/sh

- some packages can't be configured so let's execute this again:
    # PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin dpkg --configure -a

- set hostname and create root password (which is "root")
    # echo "sama5d27-sd96" > /etc/hostname
    # echo root:root | /usr/sbin/chpasswd

- now we prepare for the first real boot
    # cd /sbin
    # rm init
    # mv init.orig init
    # sync

- press Ctrl-D, the kernel will panic
- reset the board

- after startup login as root   
  execute on target:
    # swapoff -a
    # mkswap /dev/mmcblk1p3
    # swapon -a

- enable and start networking
    # systemctl enable systemd-resolved
    # systemctl enable systemd-networkd
    # systemctl start systemd-resolved
    # systemctl start systemd-networkd

- after a few seconds we should have network connection, let's check it:
    # ping google.com

- execute the following:
    # passwd -d root
    # apt-get update
    # apt-get install iw vim openssh-server openssh-client rng-tools rsyslog
- this will take some time
  when openssh-server is being set up select "2. keep the local version ..."

- let's allow passwordless login through SSH:
    # vi /etc/pam.d/common-auth
  change this line (17):
    auth    [success=1 default=ignore]      pam_unix.so nullok_secure
  to this:
    auth    [success=1 default=ignore]      pam_unix.so nullok

- now let's test the SSH connection
  find out local IP address by:
    # ifconfig eth0

  on PC execute:
    $ ssh root@<IP address of Av96>

- on target execute:
    # echo "vm.min_free_kbytes=16384" >> /etc/sysctl.conf
    # mkdir /root/deb

- create dummy linuc-libc-dev package and copy over to Shield96
  in this folder execute:
    $ equivs-build ../dummy_deb/linux-libc-dev
    $ scp linux-libc-dev_5.4-r0_all.deb root@<IP address of SD96>:deb/

- build .deb packages in Yocto BSP (assume we're in Yocto build-sd96 folder)
  change PKG format to DEB in conf/local.conf
    $ bitbake linux-at91 -c clean -f
    $ bitbake linux-at91 -C compile -f
    $ bitbake mchp-wireless-firmware -c clean -f
    $ bitbake mchp-wireless-firmware -C deploy -f
    $ scp tmp/deploy/deb/all/mchp-wireless-firmware_15.4-r0_all.deb root@<IP address of SD96>:deb/
    $ scp tmp/deploy/deb/sama5d27_sd96/kernel* root@<IP address of SD96>:deb/
    $ scp tmp/deploy/deb/cortexa5t2hf-neon-vfpv4/linux-libc-headers-dev_5.4-r0_armhf.deb root@<IP address of SD96>:deb/

- now install packages
  on target:
    # cd /root/deb/
    # dpkg -i kernel*
    # dpkg -i linux-libc-* mchp-wireless-firmware_15.4-r0_all.deb
    # echo "wilc_sdio" >> /etc/modules
    # depmod -a && reboot

    # apt-get install git build-essential python python3 python3-pip wpasupplicant iptables

- setting up WiFi: see /root/README_WLAN.txt


