#!/bin/bash
# Modified for Arch Linux from ChrUbuntu's cros-haswell-modules.sh
# for kernel 3.16

set -e

# Determine kernel version
archkernver=$(uname -r)
kernver=$(uname -r | cut -d'-' -f 1)
kex=y

# Install necessary deps to build a kernel
echo "Installing linux-headers..."
sudo pacman -S --needed linux-headers

# Grab kernel source
echo "Fetching kernel sources..."
git clone https://github.com/masmullin2000/kernel_tp_ts_bkl.git linux-${kernver}
cd linux-${kernver}

# Need this
cp /usr/lib/modules/${archkernver}/build/Module.symvers .

# Prep tree
zcat /proc/config.gz > ./.config
make olddefconfig
make prepare
make modules_prepare

echo "Building relevant modules..."
# Build only the needed directories
make SUBDIRS=drivers/platform/chrome modules
make SUBDIRS=drivers/i2c/busses modules
make SUBDIRS=drivers/input/touchscreen modules

echo "Installing relevant modules..."
# switch to using our new chromeos_laptop.ko module
# preserve old as .orig
chros_lap='/lib/modules/$archkernver/kernel/drivers/platform/chrome/chromeos_laptop.ko'
if [ -f $chros_lap ];
then
sudo mv  $chros_lap ${chros_lap}.orig
fi
sudo cp drivers/platform/chrome/chromeos_laptop.ko /lib/modules/$archkernver/kernel/drivers/platform/chrome/

if [ $kex != 'y' ];
then
# switch to using our new designware i2c modules
# preserve old as .orig
echo Non gzip kernel modules
sudo mv /lib/modules/$archkernver/kernel/drivers/i2c/busses/i2c-designware-core.ko /lib/modules/$archkernver/kernel/drivers/i2c/busses/i2c-designware-core.ko.orig
sudo mv /lib/modules/$archkernver/kernel/drivers/i2c/busses/i2c-designware-pci.ko /lib/modules/$archkernver/kernel/drivers/i2c/busses/i2c-designware-pci.ko.orig
sudo cp drivers/i2c/busses/i2c-designware-core.ko /lib/modules/$archkernver/kernel/drivers/i2c/busses/
sudo cp drivers/i2c/busses/i2c-designware-pci.ko /lib/modules/$archkernver/kernel/drivers/i2c/busses/

# switch to using our new atmel_mxt_ts.ko module
# preserve old as .orig
sudo mv /lib/modules/$archkernver/kernel/drivers/input/touchscreen/atmel_mxt_ts.ko /lib/modules/$archkernver/kernel/drivers/input/touchscreen/atmel_mxt_ts.ko.orig
sudo cp drivers/input/touchscreen/atmel_mxt_ts.ko /lib/modules/$archkernver/kernel/drivers/input/touchscreen/

else
echo GZIPed kernel modules
sudo gzip /lib/modules/$archkernver/kernel/drivers/platform/chrome/chromeos_laptop.ko
# switch to using our new designware i2c modules
# preserve old as .orig
sudo mv /lib/modules/$archkernver/kernel/drivers/i2c/busses/i2c-designware-core.ko.gz /lib/modules/$archkernver/kernel/drivers/i2c/busses/i2c-designware-core.ko.gz.orig
sudo mv /lib/modules/$archkernver/kernel/drivers/i2c/busses/i2c-designware-pci.ko.gz /lib/modules/$archkernver/kernel/drivers/i2c/busses/i2c-designware-pci.ko.gz.orig
sudo cp drivers/i2c/busses/i2c-designware-*.ko /lib/modules/$archkernver/kernel/drivers/i2c/busses/
sudo gzip /lib/modules/$archkernver/kernel/drivers/i2c/busses/i2c-designware-*.ko
# switch to using our new atmel_mxt_ts.ko module
# preserve old as .orig
sudo mv /lib/modules/$archkernver/kernel/drivers/input/touchscreen/atmel_mxt_ts.ko.gz /lib/modules/$archkernver/kernel/drivers/input/touchscreen/atmel_mxt_ts.ko.gz.orig
sudo cp drivers/input/touchscreen/atmel_mxt_ts.ko /lib/modules/$archkernver/kernel/drivers/input/touchscreen/
sudo gzip /lib/modules/$archkernver/kernel/drivers/input/touchscreen/atmel_mxt_ts.ko
fi

sudo depmod -a $archkernver

echo "Installing xf86-input-synaptics..."
sudo pacman -S --needed xf86-input-synaptics

echo "Reboot to use your touchpad!"
