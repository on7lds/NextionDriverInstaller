#!/bin/bash
#########################################################
#                                                       #
#                 NextionDriver installer               #
#                                                       #
#                 (c)2018-2019 by ON7LDS                #
#                                                       #
#                        V1.02                          #
#                                                       #
#########################################################

if [ "$(which gcc)" = "" ]; then echo "- I need gcc. Please install it." exit; fi
if [ "$(which git)" = "" ]; then echo "- I need git. Please install it." exit; fi
PATH=/opt/MMDVMHost:$PATH
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )" #"
if [ "$EUID" -ne 0 ]
  then echo "- Please run as root (did you forget to prepend 'sudo' ?)"
  exit
fi

echo "+ Getting NextionDriver ..."
cd /tmp
rm -rf /tmp/NextionDriver
git clone https://github.com/on7lds/NextionDriver.git;
cd /tmp/NextionDriver 2>/dev/null
if [ "$(pwd)" != "/tmp/NextionDriver" ]; then echo "- Getting NextionDriver failed. Cannot continue."; exit; fi


#######################################################################################

THISVERSION=$(cat NextionDriver.h | grep VERSION | sed "s/.*VERSION //" | sed 's/"//g')
TV=$(echo $THISVERSION | sed 's/\.//')
ND=$(which NextionDriver)
PISTAR=$(if [ -f /etc/pistar-release ];then echo "OK"; fi)
MMDVM=$(which MMDVMHost)
BINDIR=$(echo "$MMDVM" | sed "s/\/MMDVMHost//")
CONFIGFILE="MMDVM.ini"
CONFIGDIR="/etc/"
SYSTEMCTL="systemctl daemon-reload"
MMDVMSTOP="service mmdvmhost stop"
MMDVMSTART="service mmdvmhost start"
NDOUDSTOP="service nextion-helper stop 2>/dev/null"
NDSTOP="service nextiondriver"

#######################################################################################


compileer () {
    echo "+ Compiling ..."
    make &>> /tmp/compileer.log
    RESULT=$?
    if [ "$RESULT" != "0" ]; then
        echo ""
        echo "-------------------------------"
        echo "Compiling NextionDriver failed."
        echo " (you could check errorlog"
        echo "    /tmp/compileer.log)"
        echo "Cannot continue ..."
        echo "  S O R R Y"
        echo "-------------------------------"
        echo ""
        exit
    fi
}
checkversion () {
    NV=$(NextionDriver -V | grep version | sed 's/^.*version //' | sed 's/\.//')
    if [ "$NV" != "$TV" ]; then
        echo ""
        echo "- It seems we failed."
        echo "- ($NV != $V)"
        echo "- Sorry."
        echo ""
    exit
    fi
}
helpfiles () {
    echo "+ Copying groups and users files"
    cp $DIR/groups.txt $CONFIGDIR
    cp $DIR/stripped.csv $CONFIGDIR
}
herstart () {
    echo -e "\n+ To test if it all works as expected,"
    echo -n "+  we will reboot this hotspot, OK (Y,n) ? "
    x=""
    while [ "$x" != "n" ]; do
    read -n 1 x; while read -n 1 -t .1 y; do x="$x$y"; done
#        echo -n "[$x]"
        if [ "$x" = "" ];  then reboot; fi
        if [ "$x" = "y" ]; then reboot; fi
        if [ "$x" = "Y" ]; then reboot; fi
        if [ "$x" = "N" ]; then x="n"; fi
    done
    echo -e "\n\n+ OK, not rebooting. Trying to start mmdvmhost.\n\n"
    $SYSTEMCTL
    $MMDVMSTART
}


CHECK=""

if [ "$PISTAR" = "OK" ]; then
    sudo mount -o remount,rw / ; sudo mount -o remount,rw /boot
    CONFIGFILE="mmdvmhost"
    CONFIGDIR="/etc/"
    CHECK="PISTAR"
fi
if [ "$CHECK" = "" ]; then

echo "Bindir [$BINDIR]"
    if [ "$BINDIR" = "/opt/MMDVMHost" ]; then
        echo ""
        echo "+ Found MMDVMHost in /opt."
        echo "+ I'm going to suppose you followed "
        echo "+  https://g0wfv.wordpress.com/how-to-auto-start-mmdvmhost-as-a-service-on-boot-in-raspbian-jessie/"
        echo ""
        echo ""
        CONFIGFILE="MMDVMHost.ini"
        CONFIGDIR="/opt/MMDVMHost"
        CHECK="JESSIE"
    fi
fi
if [ "$CHECK" = "" ]; then
    echo "- I could not find out which system this is."
    echo "- At this moment, I cannot yet automaticly install NextionDriver"
    echo ""
    echo "- Sorry."
    echo ""
    exit
fi


if [ "$MMDVM" = "" ]; then
    echo ""
    echo "- No MMDVMHost found,"
    echo "- so why would you install NextionDriver ?"
    echo "- Cannot continue"
    echo ""
    echo "- Sorry."
    echo ""
    exit
fi


########## Check for older installation ##########
if [ $(cat /usr/local/sbin/mmdvmhost.service | grep extion | wc -l) -gt 0 ]; then
    echo -e "I older installation found, removing ..."
    ND=""
fi



########## Check for Install ##########
if [ "$ND" = "" ]; then
    echo "+ No NextionDriver found, trying to install one."
    compileer
    $SYSTEMCTL
    $NDOUDSTOP 2>/dev/null
    $NDSTOP
    $MMDVMSTOP
    killall -q -I MMDVMHost
    killall -9 -q -I MMDVMHost
    systemctl disable mmdvmhost
    systemctl disable nextion-helper 2>/dev/null
    systemctl disable nextiondriver
    if [ "$CHECK" = "PISTAR" ]; then 
        echo "+ found PISTAR"
        cp $DIR"/nextiondriver.service.binary.pistar" /usr/local/sbin/nextiondriver.service
        if [ $(cat /usr/local/sbin/mmdvmhost.service | grep extion | wc -l) -gt 0 ]; then
            echo "+ Restoring mmdvmhost.service binary"
            rm /usr/local/sbin/mmdvmhost.service
            git --work-tree=/usr/local/sbin/ --git-dir=/usr/local/sbin/.git checkout mmdvmhost.service
        fi
        echo "+ Installing services"
        cp $DIR"/mmdvmhost.service.pistar" /lib/systemd/system/mmdvmhost.service
        cp $DIR"/nextiondriver.service.pistar" /lib/systemd/system/nextiondriver.service
    fi
    if [ "$CHECK" = "JESSIE" ]; then 
        cp $DIR"/mmdvmhost.service.jessie" /lib/systemd/system/mmdvmhost.service
        cp $DIR"/mmdvmhost.timer.jessie" /lib/systemd/system/mmdvmhost.timer
        rm -f /lib/systemd/system/nextion-helper.service
        cp $DIR"/nextiondriver.service.jessie" /lib/systemd/system/nextiondriver.service
    fi
    cp NextionDriver $BINDIR
    systemctl enable mmdvmhost
    systemctl enable nextiondriver
    echo "+ Check version :"
    NextionDriver -V
    checkversion
    helpfiles
    echo -e "+ NextionDriver installed\n"
    echo -e "+ -----------------------------------------------"
    echo -e "+ We will now start the configuration program ...\n"
    $DIR/NextionDriver_ConvertConfig $CONFIGDIR$CONFIGFILE
    herstart
    exit
fi


########## Check for Update ##########
VERSIE=$($ND -V | grep version | sed "s/^.*version //")
V=$(echo $VERSIE | sed 's/\.//')
echo "+ NextionDriver $VERSIE found at $ND"
echo "+ We are version $THISVERSION"

if [ $TV  -gt $V ]; then
    echo "+ Start Update"
    compileer
    $SYSTEMCTL
    $NDSTOP
    $MMDVMSTOP
    killall -q -I MMDVMHost
    killall -q -I NextionDriver
    killall -9 -q -I MMDVMHost
    killall -9 -q -I NextionDriver
    cp NextionDriver $BINDIR
    echo -e "\n+ Check version"
    NextionDriver -V
    checkversion
    helpfiles
    echo -e "\n+ NextionDriver updated\n"
    herstart
else
    echo -e "\n- No need to update.\n"
    exit
fi
