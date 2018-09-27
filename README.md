NextionDriverInstaller
======================

This is the installer program for NextionDriver for those who do
not want to do it theirselves.

This is the first release. I have tested it on some hotspots
but there are always much more situations and combinations than
the ones I tested :-)

This repository also includes the cofiguration convertor program
for automatically converting the MMDVM.ini file to incorporate
NextionDriver.
You could just run it (NextionDriver_ConvertConfig) if you installed
NextionDriver by hand, but it also will be called when you run the
installer !


Please let me know if you have any problem.



##Installing NextionDriver (on Pi-Star)

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
./install.sh
```
