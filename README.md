# moOde-CD-Rip-and-Play

A companion program for the moOde audio player (http://moodeaudio.org/) to rip and tag CDs and play them. Either as 320kbps mp3 files, flac and/or mpc.

This is not a program for an alternative user interface to moOde.

It allows a user to play their CDs without using the moOde interface. The volume being adjusted using an attached rotary encoder. CDs that have already been ripped can be batch queued for playing. It sort of emulates the old fashioned juke box except that instead of feeding in money, you feed in the discs.

Is copying CDs legal? If you are not sure what the position is for the country you live in, please check your local copyright law to make sure that you are on the right side of the law before using the software featured here.

# Requirements:

  A working moOde image (tested on v6.5.0) on a Raspberry Pi3. (Rpi4 not tested).
  An external CD drive attached to the USB port.

# Download:

  Download the files using git

	git clone https://github.com/TheMetalHead/moOde-CD-Rip-and-Play.git
	cd moOde-CD-Rip-and-Play

  or with wget

	mkdir moOde-CD-Rip-and-Play
	cd moOde-CD-Rip-and-Play
	wget https://github.com/TheMetalHead/moOde-CD-Rip-and-Play/archive/master.zip -O moOde-CD-Rip-and-Play.zip
	unzip -j moOde-CD-Rip-and-Play.zip
	rm moOde-CD-Rip-and-Play.zip

  After the download, do

	chmod 544 *.sh

# Configuration:

The configuration files have the format VARIABLE=value
Except when "value" needs to be quoted or otherwise interpreted, if other variables within "value" are to be expanded upon reading the configuration file, then double quotes should be used.  If they are only supposed to be expanded upon use (for example OUTPUTFORMAT) then single quotes must be used.

All shell escaping/quoting rules apply.



Edit the configuration file as required: cd-rip-and-or-play.conf

The music files can reside in either:
MUSIC_HOME_PATH/RIPPED_MUSIC_DIR/MUSIC_SUB_DIR
or
MUSIC_HOME_PATH/RIPPED_MUSIC_DIR

MUSIC_HOME_PATH="/home/pi" : The full path to the music files. Do not add any trailing slashes.

RIPPED_MUSIC_DIR="Music-CD" : Directory containing the music files. Do not add any leading/trailing slashes.

RIPPED_MUSIC_OWNER="pi:pi" : WARNING: The owner existance is not checked.

LIBRARY_TAG="My CDs" : The name that is displayed in the 'moOde' library menu. Do not add any leading/trailing slashes.

MUSIC_MNT_SOURCE="CD" : This should be CD, NAS, USB or SDCARD. It is the name used in the '/mnt' directory. Do not add any leading/trailing slashes.

MUSIC_SUB_DIR="CD" : This is optional. It can be used to differentiate between your music files and ripped music files if they are both kept in the same 'RIPPED_MUSIC_DIR'. It must either be empty ("") or have no slashes at the first and last characters.

DEFAULT_VOLUME=10 : The default volume that 'moOde' will play the cd at.

Set the log level as required by uncommenting one of the following: #_LOG_LEVEL=${LOG_LEVEL_NOLOG} or #_LOG_LEVEL=${LOG_LEVEL_LOG} or #_LOG_LEVEL=${LOG_LEVEL_DEBUG}

All other configuration options can be left unchanged.

The configuration file: abcde.conf

  Each track is, by default, placed in a separate file named after the track in a subdirectory named after the artist under the current directory. This can be modified using the OUTPUTFORMAT and VAOUTPUTFORMAT variables in the abcde.conf file. Each file is given an extension identifying its compression format, eg '.mp3', '.flac' etc.

# Installation:

There is a bash script called 'Install-cd-rip.sh' that checks for and installs the required programs and creates the required links for moOde.

The required programs are:

  abcde
  cd-discid
  eject
  flock
  touch
  truncate
  mpc
  mpd
  cdparanoia
  lame
  flac
  mpcenc
  glyrc
  eyeD3

A bash script called 'Remove-cd-rip.sh' can be used to remove some installed files and the links for moOde:

  cd-discid
  eject
  cdparanoia
  lame
  flac
  mpcenc
  glyrc
  eyeD3

The downloaded 'moOde-CD-Rip-and-Play' files will be left untouched. These can be manually deleted. The ripped music cd will be left untouched, but the hidden disc id directory '.Music CDs Ripped' will be removed.

# Updating:

  Before installing a new version of the software, create a backup copy of the current directory excluding any sub-directories. If anything goes wrong with new version there will always be a way to rollback to the old version.

	To backup:	tar -cvpzf backup.tar.gz --no-recursion *

	To restore:	tar -xf backup.tar.gz

  The best way is to use the script called 'Update-cd-rip.sh' if it is available.

  Alternatively, from the command line:

	To update:

	cp cd-rip-and-or-play.conf cd-rip-and-or-play.conf.bak

	wget https://github.com/TheMetalHead/moOde-CD-Rip-and-Play/archive/master.zip -O moOde-CD-Rip-and-Play.zip

	chmod 744 *.sh

	unzip -j moOde-CD-Rip-and-Play.zip

	chmod 544 *.sh

	cp cd-rip-and-or-play.conf.bak cd-rip-and-or-play.conf

After the update, run the script 'Install-cd-rip.sh', there is no need to reboot.

# Usage:

  Insert the CD into the drive. The CD will be checked to see if it has been previously ripped. If not, the ripping process will take about 12 minutes. After this, the CD will be ejected and moOde will play the ripped files. If the CD has been previously ripped, it will be ejected and moOde will play the ripped files. More CDs can be inserted for batch queueing.



# Default cd cover:

	default-cd-cover.jpg comes from https://commons.wikimedia.org/wiki/File:CD_icon_test.svg under the license of https://commons.wikimedia.org/wiki/Commons:GNU_Free_Documentation_License,_version_1.2

	No changes were made to the cover.
