#!/bin/bash
# script ini yang akan melakukan compiling kernel
# Usage: kernel.sh <parameter>
# seandainya tidak ada parameter yang digunakan semua function akan dijalankan
# Christian Alexander <alexforsale@yahoo.com>

# source semua variable dari file variables.txt
if [ -e variables.txt ]; then
    echo "sourcing variables.txt"
    source variables.txt
else
    echo "variables.txt not exist, exiting"
    exit 1
fi

# variable - variable yang (sepertinya) permanen
KERNEL_MODULES_INSTALL=kernel-test/system
KERNEL_MODULES_OUT=$KERNEL_MODULES_INSTALL/lib/modules
INSTALL_MOD_PATH=kernel-test/system/lib/modules/

save_defconfig () {
    # simpan kernel config A16C3H_defconfig kedalam source kernel
    if [ ! -e $KERNEL_OUT/.config ]; then
        echo "$KERNEL_SOURCE belum memiliki .config file, copy dari A16C3H_defconfig"
        cp $KERNEL_DEFCONFIG $KERNEL_OUT/.config
    else
        echo "$KERNEL_SOURCE sudah memiliki .config sendiri"
    fi
    make --directory=$KERNEL_SOURCE ARCH=$ARCH CROSS_COMPILE=$TOOLCHAIN/$PREFIX O=$(pwd)/$KERNEL_OUT savedefconfig
    mv $(pwd)/$KERNEL_OUT/defconfig $KERNEL_SOURCE/arch/$ARCH/configs/$KERNEL_DEFCONFIG
}
mv-modules () {
    mdpath=`find $KERNEL_MODULES_OUT -type f -name modules.order`;
    if [ "$mdpath" != "" ];then
        mpath=`dirname $mdpath`;
        ko=`find $mpath/kernel -type f -name *.ko`;
        for i in $ko; do $TOOLCHAIN/"$PREFIX"strip --strip-unneeded $i;
                         mv $i $KERNEL_MODULES_OUT/
        done
    fi        
}

clean-module-folder () {
    mdpath=`find $KERNEL_MODULES_OUT -type f -name modules.order`;
    if [ "$$mdpath" != "" ];then
        mpath=`dirname $mdpath`; rm -rf $mpath;
    fi    
}
zImage () {
    #compile Zimage
    echo "compiling zImage"
    make --directory=$KERNEL_SOURCE ARCH=$ARCH CROSS_COMPILE=$TOOLCHAIN/$PREFIX O=$(pwd)/$KERNEL_OUT $KERNEL_DEFCONFIG
    make --jobs=$JOBS --directory=$KERNEL_SOURCE ARCH=$ARCH CROSS_COMPILE=$TOOLCHAIN/$PREFIX O=$(pwd)/$KERNEL_OUT zImage
    cp $KERNEL_OUT/arch/arm/boot/zImage zImage
}

dtbs () {
    #compile dtbs
    if grep -q 'CONFIG_OF=y' $KERNEL_DEFCONFIG ; then
        echo "compiling DTBs"
        make --jobs=$JOBS --directory=$KERNEL_SOURCE ARCH=$ARCH CROSS_COMPILE=$TOOLCHAIN/$PREFIX O=$(pwd)/$KERNEL_OUT dtbs
    else
        echo "dtb not enabled"
    fi
}

modules () {
    #compile modules
    if grep -q 'CONFIG_MODULES=y' $KERNEL_DEFCONFIG ;then
        echo "compiling modules"
        make --jobs=$JOBS --directory=$KERNEL_SOURCE ARCH=$ARCH CROSS_COMPILE=$TOOLCHAIN/$PREFIX O=$(pwd)/$KERNEL_OUT modules
        make --jobs=$JOBS --directory=$KERNEL_SOURCE ARCH=$ARCH CROSS_COMPILE=$TOOLCHAIN/$PREFIX O=$(pwd)/$KERNEL_OUT INSTALL_MOD_PATH=../$KERNEL_MODULES_INSTALL modules_install
        mv-modules
        clean-module-folder
    else
        echo "modules not enabled"
    fi
}

clean () {
    make --jobs=$JOBS --directory=$KERNEL_SOURCE O=$(pwd)/$KERNEL_OUT mrproper
}

all () {
    # make config
    make --directory=$KERNEL_SOURCE ARCH=$ARCH CROSS_COMPILE=$TOOLCHAIN/$PREFIX O=$(pwd)/$KERNEL_OUT $KERNEL_DEFCONFIG
    make --jobs=$JOBS --directory=$KERNEL_SOURCE ARCH=$ARCH CROSS_COMPILE=$TOOLCHAIN/$PREFIX O=$(pwd)/$KERNEL_OUT all
    cp $KERNEL_OUT/arch/arm/boot/zImage zImage
}

# parameter - parameter yang dipakai
case $1 in
    "zImage")
        zImage
        ;;
    "dtbs")
        dtbs
        ;;
    "modules")
        modules
        ;;
    "clean")
        clean
        ;;
    "savedefconfig")
        save_defconfig
        ;;
    "all")
        all
        modules
        ;;
    *)
        echo "tidak ada parameter, diasumsikan all"
        all
        modules
        ;;
esac
