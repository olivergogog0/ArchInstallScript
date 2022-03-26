# Arch linux 安装脚本

本脚本基于[arch icekylin](https://arch.icekylin.online/)中提到的相关技术和[fabric-samples](https://github.com/hyperledger/fabric-samples)的脚本范例而写。

使用UEFI启动，使用BTRFS分区

获取脚本后
```sh
chmod +x  ./install.sh
```

根据icekylin中的步骤，可以将整体安装步骤分为四个部分
- 硬盘分区前的准备
- 硬盘分区后的格式化，挂载，生成fstab文件
- 使用pacstrap 安装基础系统和必要软件。chroot到/mnt，
- 在/mnt的系统中配置host,时区，密码，安装微码，安装bootloader并生成grub配置文件

## 自行选择工具进行硬盘分区，完成分区后自行修改脚本中相关的路径

目前此脚本在虚拟机中可以成功运行，几分钟即可完成安装。

使用举例
```
./install.sh p 
cfdisk /dev/nvme0n1 
vim ./install.sh
./install.sh f
./install.sh i
./install.sh b
exit
umount -R /mnt
reboot
```

镜像启动不支持中文，所以脚本注释都使用我的蹩脚英语而写

此脚本有些描述上的问题可以进一步修改。可以增加一些新功能。比如调整分辨率

基本框架已经有了，后续稍微修改就可以分出单机脚本，双系统脚本。

先提交一个能用的版本，获得一点成就感。后续抽时间完善。

欢迎交流。
