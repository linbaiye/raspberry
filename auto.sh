#!/bin/bash
make 
if [ $? -ne 0 ]; then
    echo make error.
    exit 1
fi
rm /media/lintao/boot/kernel.img
if [ $? -ne 0 ]; then
    echo remove error.
    exit 1
fi
cp kernel.img /media/lintao/boot
if [ $? -ne 0 ]; then
    echo copy error.
    exit 1
fi
umount /media/lintao/boot
echo SD card can be removed safely.
