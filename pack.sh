#!/bin/bash -x
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
    dtb=dt.img
}

ramdisk () {
    # pack directory ramdisk menjadi ramdisk.img
    echo "packing ramdisk.img"
    bin/mkbootfs ramdisk/ | minigzip > ramdisk.img
    ramdisk=ramdisk.img
}

boot () {
    # pack dtb, ramdisk dan zImage menjadi boot.img
    echo "packing boot.img"
    mkbootimg --kernel zImage --ramdisk ramdisk.img --cmdline "$CMDLINE" --base $BASE --ramdisk_offset $RAMDISK_OFFSET --tags_offset $TAGS_OFFSET --dt dt.img --output kernel-test/boot.img
    boot=kernel-test/boot.img
}

zip () {
    # pack kernel-test.zip
    for i in $(ls kernel-test/)
    do
        zip -r kernel-test.zip kernel-test/$i
    done
    zip=kernel-test.zip
}

clean () {
    for output in $(ls $dtb $ramdisk $boot $zip); do
        rm $output
    done
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
        zip
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
