#! /bin/sh

fail()
{
        if [ $1 -ne 0 ]; then
                echo [distroot] command failed!
                exit 1
        fi
}

program()
{
        echo ""
        echo "1 SD card"
        echo "2 eMMC"
        echo "3 USB disk"
        echo ""

        if [ -z "$id" ]; then
                read -p " Choose the flash [1-3]: " id
                echo
        else
                id=1
        fi

        case $id in
                1) DEV=mmcblk0;;
                2) DEV=mmcblk1;;
                3) DEV=sda;;
        esac

        echo [distroot] check id exits
        ls /dev/${DEV}
        fail $?

        echo [distroot] format the disk
        echo -e "d\n1\nd\n2\nd\n3\nd\n4\nd\nw" | fdisk /dev/${DEV}
        fail $?

	echo [distroot] program the flash...
	xzcat roc-rk3399-pc-distroot.img.xz | dd of=/dev/${DEV} status=progress
        fail $?
        sync
     	fail $?

        echo [distroot] remove the distroot image from initramfs
        rm -rf roc-rk3399-pc-distroot.img*
        fail $?
}

echo [distroot] Started...

echo [distroot] download distroot image...
wget --no-check-certificate https://bitbucket.org/amarula/distroot/raw/497fe85a96e7baeec905a406b5e173a3a0769837/roc-rk3399-pc-distroot.img.xz
fail $?

echo [distroot] try to program the flash...
program

echo [distroot] mount boot
partprobe /dev/${DEV}
fail $?
if [ "${DEV}" = "sda" ]; then
        mount /dev/${DEV}1 /mnt
else
        mount /dev/${DEV}p1 /mnt
fi
fail $?

echo [distroot] update root
if [ "${DEV}" = "sda" ]; then
	sed -i "s/mmcblk0p/${DEV}/g" /mnt/grub.cfg
else	
	sed -i "s/mmcblk0/${DEV}/g" /mnt/grub.cfg
fi

echo [distroot] umount boot
umount -l /mnt
fail $?

echo [distroot] end!
