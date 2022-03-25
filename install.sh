#/usr/bin/zsh

. ./env.sh
. ./utils.sh


# function forbidReflector2(){
#     infoln "forbid the reflector service"
#     systemctl stop reflector.service
# }

# function checkUEFI2(){
#     infoln "check boot mood "
#     if test ! -z "$(ls /sys/firmware/efi/efivars)"; then
#         successln "boot via UEFI"
#     else  
#         errorln "boot not via UEFI !"
#     fi
# }
# function checkNetwork2(){
#     infoln "check network connection"
#     if test ! -z "$(ping ${PINGSITE} -c 4)"; then
#         successln "network connected "
#     else 
#         errorln "ping failed !"
#     fi
# }

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

function partitionDisk(){
    warnln "partition the disk is a very dengerous move"
    warnln "NO script for it"
    warnln "Do it your self "
}

function prepare(){
    forbidReflector
    checkUEFI
    # checkNetwork
    updateSystemClock
    updateMirrorServer
    partitionDisk
}

prepare





