NextionDriver Installer and Checker
===================================

##NextionDriver Installer

This is the installer program for NextionDriver for those who do
not want to do it by hand.

This is the first release. I have tested it on some hotspots
but there are always much more situations and combinations than
the ones I tested :-)

This repository also includes the configuration convertor program
for automatically converting the MMDVM.ini file to incorporate
NextionDriver.
You could just run it (NextionDriver_ConvertConfig) if you installed
NextionDriver by hand, but it also will be called when you run the
installer !

_**For the moment, both programs are intended for Pi-Star hotspots.**_

Please let me know if you have any problem.



### Installing NextionDriver (on Pi-Star)

log in to your Pi-Star with SSH

* use PuTTY
* or go to your dashboard -> configuration -> expert -> SSH access (http://pi-star.local/admin/expert/ssh_access.php)

go to the /tmp directory
```
cd /tmp
```

get the installer
```
git clone https://github.com/on7lds/NextionDriverInstaller.git
```

go !
```
sudo NextionDriverInstaller/install.sh
```


##NextionDriver Checker

This programs tries to check the MMDVMHost and NextionDriver
configuration.

### Checking NextionDriver installation (on Pi-Star)

log in to your Pi-Star with SSH

* use PuTTY
* or go to your dashboard -> configuration -> expert -> SSH access (http://pi-star.local/admin/expert/ssh_access.php)

go to the /tmp directory
```
cd /tmp
```

get the installer
```
git clone https://github.com/on7lds/NextionDriverInstaller.git
```

go !
```
sudo NextionDriverInstaller/check_installation.sh
```

The program then gives a lot of information about the installation
of the NextionDriver and if it seems to be OK or not.
