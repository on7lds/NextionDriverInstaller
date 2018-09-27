#!/bin/bash
#########################################################
#                                                       #
#                 NextionDriver installer               #
#                                                       #
#                   (c)2018 by ON7LDS                   #
#                                                       #
#                        V1.00                          #
#                                                       #
#########################################################

if [ "$(which gcc)" = "" ]; then echo "- I need gcc. Please install it." exit; fi
if [ "$(which git)" = "" ]; then echo "- I need git. Please install it." exit; fi

echo "+ Getting NextionDriver ..."
cd /tmp
rm -rf /tmp/NextionDriver
git clone https://github.com/on7lds/NextionDriver.git;
cd /tmp/NextionDriver
if [ "$(pwd)" != "/tmp/NextionDriver" ]; then echo "- Getting NextionDriver failed. Cannot continue."; exit; fi


#########################################################

THISVERSION=$(cat NextionDriver.h | grep VERSION | sed "s/.*VERSION //" | sed 's/"//g')
TV=$(echo $THISVERSION | sed 's/\.//')
ND=$(which NextionDriver)
PISTAR=$(if [ -f /etc/pistar-release ];then echo "OK"; fi)
MMDVM=$(which MMDVMHost)
BINDIR=$(echo "$MMDVM" | sed "s/MMDVMHost//")
CONFIGFILE="MMDVM.ini"
CONFIGDIR="/etc"
MMDVMSTART="service mmdvmhost restart"

#########################################################

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
    cp /tmp/NextionDriverInstaller/groups.txt $CONFIGDIR
    cp /tmp/NextionDriverInstaller/stripped.csv $CONFIGDIR
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
    $MMDVMSTART
}


if [ "$EUID" -ne 0 ]
  then echo "- Please run as root"
  exit
fi


if [ "$PISTAR" = "OK" ]; then
    sudo mount -o remount,rw / ; sudo mount -o remount,rw /boot
    CONFIGFILE="mmdvmhost"
    CONFIGDIR="/etc/"
    MMDVMSTART="service mmdvmhost restart"
else
    echo ""
    echo "- This is not a Pi-Star."
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


########## Check for Install ##########
if [ "$ND" = "" ]; then
    echo "+ No NextionDriver found, trying to install one."
    compileer
    service mmdvmhost stop
    killall -q -I MMDVMHost
    cp NextionDriver $BINDIR
    echo "+ Check version :"
    NextionDriver -V
    checkversion
    helpfiles
    echo -e "+ NextionDriver installed\n"
    echo -e "+ -----------------------------------------------"
    echo -e "+ We will now start the configuration program ...\n"
    ./NextionDriver_ConvertConfig $CONFIGDIR$CONFIGFILE
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
    service mmdvmhost stop
    killall -q -I MMDVMHost
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
