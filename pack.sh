#!/bin/bash
# script ini yang akan melakukan packing boot.img
# USAGE: pack.sh <parameter>
# seandainya tidak ada parameter semua function akan dijalankan
# Christian Alexander <alexforsale@yahoo.com>

# source semua variable dari file variables.txt
if [ -e variables.txt ]; then
    echo "sourcing variables.txt"
    source variables.txt
else
    echo "variables.txt not exist, exiting"
    exit 1
fi

# masukkan semua binary di bin/ kedalam PATH
export PATH=$(pwd)/bin/:$PATH
# dtbToolCM
dtb () {
    # Pack dtb menjadi dt.img
    echo "packing dt.img"
    bin/dtbToolCM --force-v2 -o dt.img -s $PAGESIZE -p $KERNEL_OUT/scripts/dtc/ $KERNEL_OUT/arch/$ARCH/boot/dts/
}

ramdisk () {
    # pack directory ramdisk menjadi ramdisk.img
    echo "packing ramdisk.img"
    bin/mkbootfs ramdisk/ | minigzip > ramdisk.img
}

boot () {
    # pack dtb, ramdisk dan zImage menjadi boot.img
    echo "packing boot.img"
    mkbootimg --kernel zImage --ramdisk ramdisk.img --cmdline "$CMDLINE" --base $BASE --ramdisk_offset $RAMDISK_OFFSET --tags_offset $TAGS_OFFSET --dt dt.img --output kernel-test/boot.img
}

clean () {
    dtb=dt.img
    boot=kernel-test/boot.img
    ramdisk=ramdisk.img
    zip=kernel-test.zip
    rm $dtb
    rm $ramdisk
    rm $boot
    rm $zip
}

# parameter
case $1 in
    "dtb")
        dtb
        ;;
    "ramdisk")
        ramdisk
        ;;
    "boot")
        boot
        ;;
    "zip")
        echo "zip kernel-test.zip"
        ;;
    "all")
        dtb
        ramdisk
        boot
        zip
        ;;
    "clean")
        clean
        ;;
    *)
        echo "tidak ada parameter, diasumsikan all"
        dtb
        ramdisk
        boot
        zip
        ;;
esac

if [ "$1" = "zip" ] || [ "$1" = "all" ] || [ "$1" = "" ]; then
    cd kernel-test/
    zip -r ../kernel-test.zip META-INF/ boot.img system/
fi
