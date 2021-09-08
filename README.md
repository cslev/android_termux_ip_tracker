# android_termux_ip_tracker
This script runs on (non-rooted) Android, in termux terminal, and logs mobile data IPv4/6 addresses along with date and location data.

## Requirements
Install `Termux` and `Termux-API` Android packages from F-droid (Not from play store as they are outdated)

[Termux apk](https://f-droid.org/en/packages/com.termux/)

[Termux-API apk](https://f-droid.org/en/packages/com.termux.api/)

Note, if Termux is installed through google play store then delete first. Otherwise Termux-API from F-droid will collide with it.

### Install termux-api pkg inside termux. 
Launch Termux from your phone, upgrade pacakge list and install `termux-api` package to have the required binaries
```
pkg upgrade
pkg install termux-api
```

### check whether Termux API works properly
Try to get location data (it takes some time, so be patient and have good GPS reception)
```
termux-location
```
It will ask for LOCATION permission first, so maybe you have to run it for the second time.

## Run android_termux_ip_tracker
First, install `git` in termux
```
pkg install git
```
Then, download sources
```
git clone https://github.com/cslev/android_termux_ip_tracker
```

Run script by checking the help first
```
This script stores the IP addesses of the data communication interfaces with location+date information to keep track of them preciesly!
Example: ./ip_addr_logger.sh [-a INTF1 -b INTF2 -s SLEEP_TIME]
		-a <INTF1>: set the primary interface name that is used to connect to the internet via mobile data communication (Default: intf1).
		-b <INTF2>: set the secondary interface name that is used to connect to the internet via mobile data communication (Default: intf2).
		-s <SLEEP_TIME>: sleep time IN SECONDS between two consecutive measurements. Cannot be less than 5 seconds (Default: 300).
How to simply get these interfaces on a non-rooted phone? just use 'ip addr show' and look for the interfaces that have meaningful IP addresses
```

### Example
```
./ip_addr_logger.sh -a rmnet_data0 -b rmnet_data2 -s 100
```
Log files will be created in the same directory! And, by running the script, termux acquire wake lock, i.e., it won't be killed by Android and will be running even with screen off. 
This also means increased battery consumption for the convenience.


