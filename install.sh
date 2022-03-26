#/usr/bin/zsh

#configs 

# ping ustc for checking the network
export PINGSITE="ustc.edu.cn"

# use ustc mirror server as default, 
export MIRRORSERVER="Server = https://mirrors.ustc.edu.cn/archlinux/\$repo/os/\$arch"
# export MIRRORSERVER="Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/$repo/os/$arch"

# disk partition config
export EFI=/dev/nvme0n1p1
export SWAP=/dev/nvme0n1p2
export MAIN=/dev/nvme0n1p3

# btrfs label e.g. mkfs.btrfs -L myArch /dev/sdxn
export BTRFSLABEL="myARCH"

export HOSTNAME="arch"

export CPU="amd"
#epoxrt CPU="intel"

C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_BLUE='\033[0;34m'
C_YELLOW='\033[1;33m'

# println echos string
function println() {
    echo
    echo -e "$1"
}

# errorln echos i red color
function errorln() {
  println "${C_RED}${1}${C_RESET}"
}

# successln echos in green color
function successln() {
  println "${C_GREEN}${1}${C_RESET}"
}

# infoln echos in blue color
function infoln() {
  println "${C_BLUE}${1}${C_RESET}"
}

# warnln echos in yellow color
function warnln() {
  println "${C_YELLOW}${1}${C_RESET}"
}

# fatalln echos in red color and exits with fail status
function fatalln() {
  errorln "$1"
  exit 1
}

function printHelp() {
    successln "Welcome to use the Arch Install Script writen by oliver !"
    infoln "now print the usage message for this script"

    println "./install.sh "

    println "Flags: "

    successln " p \n\t prepare the system config. after this, you should partition your disks yourself "
    infoln "\t including forbid the annoying speaker and reflector service, check for UEFI and the network connection, update system clock and the mirror server"

    successln " f \n\t format the partitions. before this, you should edit this script for paths of the partitions"
    infoln "\t including format the EFI, SWAP and the main partition. create the subvolume in btrfs. start the swap. mount the EFI and the main partition"

    successln " i \n\t install base system "
    infoln "\t including pacstrap, generate fstab files. chroot to the /mnt and copy this script to /mnt/home for next step"

    successln " b \n\t basic setup and install for system. "
    infoln "\t set host, timezone,and root passwd. sync hwc, install ucode and bootloader, generate the grub files"
}

function forbidSpeaker() {
    infoln "forbit the speak"
    set -x
    echo "rmmod pcspkr" >> /etc/profile
    set +x
}

function forbidReflector() {
    infoln "forbid the reflector service "
    set -x
    systemctl stop reflector.service 
    res=$?
    systemctl status reflector.service > log.txt
    { set +x; } 2>/dev/null
    if [ $res -eq 0 ]; then
        successln "forbid success"
        cat log.txt
    else 
        fatalln "Failed to forbid reflector service"
    fi
}

function checkUEFI(){
    infoln "check boot mode"
    if [ -d "/sys/firmware/efi/efivars" ]; then
        ls /sys/firmware/efi/efivars
        successln "Boot in UEFI mode successfully"
    else 
        fatalln "Failed to boot in UEFI mode !"
    fi
}

function checkNetwork(){
    infoln " check network connection"
    set -x 
    ping ${PINGSITE} -c 4 > log.txt
    res=$?
    { set +x; } 2>/dev/null
    if [ $res -ne 0 ]; then
        fatalln "Failed to connect network !"
    else 
        cat log.txt
        successln "network connected "
    fi
}

function updateSystemClock(){
    infoln "update the system clock"
    set -x
    timedatectl set-ntp true 
    { set +x; } 2>/dev/null
    if [ $res -eq 0 ]; then
        timedatectl status 
        successln "update clock successfully "
    else 
        fatalln "Failed to update the system clock !"
    fi
}
function updateMirrorServer(){
    infoln "update the mirror server"
    dateStr=$(date +%Y_%m_%d_%H_%M_%S)
    set -x 
    cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.${dateStr}.backup
    echo "${MIRRORSERVER}" > /etc/pacman.d/mirrorlist
    { set +x; } 2>/dev/null
    if [ $res -eq 0 ]; then
        successln "update mirror server successfully"
    else 
        fatalln "Failed to update the mirror server"
    fi
}

function beforePartition(){
    warnln "partition the disk is a very dengerous move"
    warnln "NO script for it"
    warnln "Do it your self "
    infoln "After partition, edit the config for this script !" 
    fdisk -l
}

function formatEFI(){
    infoln "format the EFI"
    set -x
    mkfs.vfat ${EFI} > log.txt
    res=$?
    { set +x; } 2>/dev/null
    if [ $res -ne 0 ]; then 
        fatalln "Filed to format the EFI "
    else 
        successln "format EFI successfully"
    fi
}

function formatSWAP(){
    infoln "format the SWAP"
    set -x
    mkswap ${SWAP} > log.txt
    res=$?
    { set +x; } 2>/dev/null
    if [ $res -ne 0 ]; then 
        fatalln "Failed to format the SWAP"
    else 
        successln "format SWAP successfully"
    fi
}

function formatBTRFS(){
    infoln "format BTRFS"
    infoln "format ${MAIN}"
    set -x
    mkfs.btrfs -L ${BTRFSLABEL} ${MAIN} > log.txt
    res=$?
    { set +x; } 2>/dev/null
    if [ $res -ne 0 ]; then 
        fatalln "Failed to format the main partition"
    else 
        successln "format the main partition successfully"
    fi

    infoln "create subvolume"
    set -x
    mount -t btrfs -o compress=zstd ${MAIN} /mnt > log.txt
    btrfs subvolume create /mnt/@ >> log.txt
    btrfs subvolume create /mnt/@home >> log.txt
    btrfs subvolume list -p /mnt >> log.txt
    df -h >> log.txt
    umount /mnt
    res=$?
    { set +x; } 2>/dev/null
    if [ $res -ne 0 ]; then 
        fatalln "Failed to create subvolume"
    else
        successln "create subvolume successfully"
    fi
    cat log.txt

    infoln "mount patittions"
    set -x
    mount -t btrfs -o subvol=/@,compress=zstd ${MAIN} /mnt
    mkdir /mnt/home
    mount -t btrfs -o subvol=/@home,compress=zstd ${MAIN} /mnt/home
    mkdir -p /mnt/boot/efi
    mount ${EFI} /mnt/boot/efi
    swapon ${SWAP}
    df -h > log.txt
    free -h >> log.txt
    res=$?
    { set +x; } 2>/dev/null
    if [ $res -ne 0 ]; then 
        fatalln "Failed to mount partitions"
    else
        successln "mount partitions successfully"
    fi
    cat log.txt
}
function installSystem(){
    infoln "install base system "
    set -x 
    pacstrap /mnt base base-devel linux linux-firmware 
    pacstrap /mnt dhcpcd iwd vim sudo zsh
    set +x
}

function generateFstab(){
    infoln "generate fstab"
    set -x
    genfstab -U /mnt > /mnt/etc/fstab
    res=$?
    { set +x; } 2>/dev/null
    if [ $res -ne 0 ]; then 
        fatalln "Failed to generate fstab"
    else
        successln "generate fstab successfully, cat the fstab:"
        cat /mnt/etc/fstab
    fi
}

function chroot(){
    infoln "chroot to /mnt"
    infoln "run the following :"
    infoln "cd home"
    infoln "./install.sh b - set basic config for system in next step"
    set -x 
    cp ./install.sh /mnt/home/install.sh
    arch-chroot /mnt
    set +x

}

function basic(){
    infoln "set Host and timezone"
    set -x
    echo ${HOSTNAME} > /etc/hostname 
    echo "127.0.0.1   localhost" > /etc/hosts
    echo "::1         localhost" >> /etc/hosts
    echo "127.0.1.1   myarch.localdomain 	${HOSTNAME}" >> /etc/hosts
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    set +x

    infoln "sync harware time"
    set -x
    hwclock --systohc
    set +x

    infoln "set Locale"
    set -x
    sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
    sed -i 's/#zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/' /etc/locale.gen
    locale-gen 
    echo 'LANG=en_US.UTF-8'  > /etc/locale.conf
    set +x

    infoln "set password for root"
    set -x
    passwd root
    set +x 

    infoln "install ucode"
    set -x
    pacman -S ${CPU}-ucode
    set +x
}

function bootLoader(){
    infoln "install efi packages "
    set -x
    pacman -S grub efibootmgr os-prober
    set +x

    infoln "install grub on efi partition"
    set -x 
    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=${HOSTNAME} 
    set +x

    infoln "change grub file"
    set -x
    sed -i 's/loglevel=3 quiet/loglevel=5 nowatchdog/' /etc/default/grub
    echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
    grub-mkconfig -o /boot/grub/grub.cfg
    set +x 
}

function finishInstall(){
    infoln "finish install"
    infoln "umount -R /mnt"
    infoln "reboot"
    set -x 
    exit
    set +x
    
}

# prepare before user partition the disk
function prepare(){
    forbidSpeaker
    forbidReflector
    checkUEFI
    checkNetwork
    updateSystemClock
    updateMirrorServer
    beforePartition
}

#format after user partition the disk
function formatPartition(){
    fdisk -l
    formatEFI
    formatSWAP
    formatBTRFS
}

function askContinue(){
    infoln "the next step is ${1}"
    warnln "Are sure you want to continue ? [Y/n]"
    read input
    case "$input" in
        "N" | "n") 
        fatalln "User choose to exit"
        ;;
        *)
        ;;
    esac
}


cmd=$1

case "$cmd" in
    "p" | "prepare" )
    askContinue "forbid the speaker and reflector. check UEFI and network, update the system clock and mirror server"
    prepare
    ;;
    "f" | "format" )
    infoln "after you partition the disk yourself and edit the env of this script"
    askContinue "format EFI, SWAP and the main partition. create subvolumes on btrfs. mount the partition "
    formatPartition
    ;;
    "i" | "install" )
    infoln "after format, create and mount "
    askContinue "install base system by pacstrap. generate fstab files. chroot to the /mnt and copy this script to /mnt/home"
    installSystem
    generateFstab
    chroot
    ;;
    "b" | "basic" )
    infoln " after pacstrap, fstab, chroot"
    askContinue "set hostname, hosts and timezones. sync the hwc. set locale. set root passwd. install ucode. install bootloader "
    basic
    bootLoader
    finishInstall
    ;;
    "")
    printHelp
    ;;
    *)
    warnln "invalid input !"
    printHelp
    exit
    ;;
esac







