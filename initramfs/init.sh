#!/bin/sh

# 1. 创建必要的设备节点，解决 unable to open an initial console
mknod -m 600 /dev/console c 5 1 2>/dev/null || true
mknod -m 666 /dev/null c 1 3 2>/dev/null || true

# 2. 挂载虚拟文件系统
mount -t proc proc /proc
mount -t sysfs sys /sys
mount -t devtmpfs dev /dev 2>/dev/null || true

echo ">>> Initramfs: 开始检查 eMMC 分区..."

PART="/dev/mmcblk0p1"
ROOTFS_DEV="/dev/mmcblk0p1"

# 3. 检查并创建分区
if [ -b "$PART" ]; then
    echo ">>> 分区 $PART 已存在，跳过创建。"
else
    echo ">>> 分区 $PART 不存在，正在创建..."
    (
      echo n
      echo p
      echo 1
      echo 49152
      echo ""
      echo w
    ) | fdisk /dev/mmcblk0
    
    sync
    sleep 1
    echo ">>> 分区创建完成，重启系统..."
    reboot -f
fi

# 4. 挂载根文件系统并切换
echo ">>> 正在挂载根文件系统 $ROOTFS_DEV 到 /newroot..."
mkdir -p /newroot
mount -t ext4 "$ROOTFS_DEV" /newroot

if [ $? -ne 0 ]; then
    echo "!!! 挂载失败，进入恢复 Shell..."
    exec sh
fi

echo ">>> 挂载成功，切换到真正的根文件系统..."
exec switch_root /newroot /sbin/init
