#!/bin/bash

#   Copyright (C) by Lieven De Samblanx ON7LDS
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

#########################################################
#                                                       #
#          NextionDriver_InstallationChecker            #
#                                                       #
#                   (c)2018 by ON7LDS                   #
#                                                       #
#  This program checkes the MMDVMHost configuration     #
#   and NextionDriver configuration files               #
#                                                       #
#                        V1.01                          #
#                                                       #
#########################################################

#PATH=/opt/MMDVMHost:$PATH
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )" #"
if [ "$EUID" -ne 0 ]
  then echo "- Please run as root (did you forget to prepend 'sudo' ?)"
  exit
fi

#######################################################################################

PISTAR=$(if [ -f /etc/pistar-release ];then echo "OK"; fi)
MMDVM=$(which MMDVMHost)
ND=$(which NextionDriver)
BINDIR=$(echo "$MMDVM" | sed "s/\/MMDVMHost//")
CONFIGFILE="/etc/MMDVM.ini"

#######################################################################################

CHECK=""

if [ "$PISTAR" = "OK" ]; then
    CONFIGFILE="/etc/mmdvmhost"
    CHECK="PISTAR"
    echo "+ This seems to be Pi-Star"
fi
if [ "$CHECK" = "" ]; then
    if [ "$BINDIR" = "/opt/MMDVMHost" ]; then
        CONFIGFILE="/opt/MMDVMHost/MMDVMHost.ini"
        CHECK="JESSIE"
    fi
fi

echo "----------------------"
echo "Searching MMDVMHost ..."
echo "-----------------------"
if [ "$MMDVM" = "" ]; then
    MMDVM=$(find / -executable | grep "MMDVMHost$")
    AANT=$(echo "$MMDVM" | wc -l)
    if [ "$AANT" -gt 1 ]; then
        echo "- Found more than one binary !"
    fi
fi
if [ "$MMDVM" = "" ]; then
    echo "- MMDVMHost not found"
else
    echo "+ MMDVMHost found at $MMDVM"
fi

echo "+ Searching MMDVMHost configuration file ..."
CONFIGOK=""
if [ -f "$CONFIGFILE" ]; then
    CONFIGOK=$(cat $CONFIGFILE | grep General)
fi
if [ "$CONFIGOK" = "" ]; then
    C=$(find /etc/systemd/ -name '*' -exec cat {} \; 2>/dev/null | grep "MMDVMHost " | grep Start)
    CONFIGFILE=$(echo $C | sed "s/.*MMDVMHost //")
    CONFIGOK=$(cat "$CONFIGFILE" | grep General)
fi
if [ "$CONFIGFILE" = "" ]; then
    echo "- MMDVMHost configuration file not found"
else
    echo "+ MMDVMHost configuration file found at $CONFIGFILE"
fi

if [ "$CONFIGFILE" != "" ]; then
NEXTIONPORT_IS_MODEM=""
NEXTIONPORT_IS_DRIVER=""
TRANSPARENT=""
ND_CONFIG=""
SAMEN=""
while IFS='' read -r line || [[ -n "$line" ]]; do
    #sectie bepalen
    if [[ "${line:0:1}" == "[" ]]; then
        SECTION=${line:1:-1}
    fi
    #Port van Nextion zoeken,.
    if [[ "$SECTION" == "Nextion" && "$line" == "Port="* ]]; then
        MMDVM_PORT=$(echo "$line" | sed "s/.*=//")
        echo "I    Serial port for Nextion is $MMDVM_PORT"
    fi
    if [[ "$SECTION" == "Nextion" && "$line" == "Port="*"ttyNextionDriver" ]]; then
        B="+ MMDVMHost is configured for NextionDriver"
        echo $B
        SAMEN="$SAMEN$B\n"
        ND_CONFIG="ok"
    fi
    if [[ "$SECTION" == "Transparent Data" && "$TRANSPARENT" == "" ]]; then
        echo "+    Transparent Data section found"
        TRANSPARENT="0"
    fi
    if [[ "$SECTION" == "Transparent Data" && "$line" == "Enable=1" ]]; then
        echo "I    Transparent Data Enabeled"
        TRANSPARENT="1"
    fi
    if [[ "$SECTION" == "Transparent Data" && "$TRANSPARENT" == "1" && "$line" == "SendFrameType=1" ]]; then
        TRANSPARENT="2"
        echo "I    SendFrameType enabled"
    fi
done < "$CONFIGFILE"
if [ "$ND_CONFIG" = "" ]; then
    echo "- ERROR ERROR ERROR ERROR ERROR:"
    B="- MMDVMHost is NOT configured for NextionDriver !!!"
    echo $B
    SAMEN="$SAMEN$B\n"
fi

fi

echo ""
echo "--------------------------"
echo "Searching NextionDriver ..."
echo "---------------------------"
if [ "$ND" = "" ]; then
    ND=$(find / -executable | grep "NextionDriver$")
    AANT=$(echo "$ND" | wc -l)
    if [ "$AANT" -gt 1 ]; then
        echo "- Found more than one binary !"
    fi
fi
if [ "$ND" = "" ]; then
    echo "- NextionDriver not found"
else
    echo "+ NextionDriver found at $ND"
fi

if [ "$CONFIGFILE" != "" ]; then
while IFS='' read -r line || [[ -n "$line" ]]; do
    #sectie bepalen
    if [[ "${line:0:1}" == "[" ]]; then
        SECTION=${line:1:-1}
    fi
    #Port van Nextion zoeken,.
    if [[ "$SECTION" == "NextionDriver" && "$line" == "Port="* ]]; then
        ND_PORT=$(echo "$line" | sed "s/.*=//")
        echo "I    Nextion is connected to $ND_PORT"
    fi
done < "$CONFIGFILE"
if [ "$ND_PORT" != "modem" ]; then
    if [ -w "$ND_PORT" ]; then
        echo "+ Nextion seems to be connected to an active port"
        echo $B
        SAMEN=$SAMEN"+ The Nextion display must be connected to $ND_PORT\n"
    else
        echo "+ Nextion IS NOT connected to an existing port"
    fi
else
    SAMEN=$SAMEN"+ The Nextion display must be connected to the modem\n"
fi
fi

echo ""
echo "----------------------------"
echo "Checking active programs ..."
echo "----------------------------"

MMDVM_ACT=$(pidof MMDVMHost)
if [ "$MMDVM_ACT" = "" ]; then
    echo "- MMDVMHost not running"
    SAMEN=$SAMEN"- MMDVMHost is NOT running\n"
else
    echo "+ MMDVMHost running with PID $MMDVM_ACT"
    SAMEN=$SAMEN"+ MMDVMHost is running\n"
fi

ND_ACT=$(pidof NextionDriver)
if [ "$ND_ACT" = "" ]; then
    echo "- NextionDriver not running"
    SAMEN=$SAMEN"- NextionDriver is NOT running\n"
else
    echo "+ NextionDriver running with PID $ND_ACT"
    SAMEN=$SAMEN"+ NextionDriver is running\n"
fi

echo ""
echo "--------------------------------"
echo "|            REPORT            |"
echo "--------------------------------"
echo -e "$SAMEN"
