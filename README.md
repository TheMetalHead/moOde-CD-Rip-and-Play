# moOde-CD-Rip-and-Play

A companion program for the moOde audio player (http://moodeaudio.org/) to rip and tag CDs to 320kbps mp3 files and play them.

This allows a user to play their CDs without using the moOde interface. The volume being adjusted using an attached rotary encoder.
CDs that have already been ripped can be batch queued for playing.

# Requirements:

  A working moOde image (tested on v6.5.0) on a Raspberry Pi3 . (Rpi4 not tested).
  An external CD drive attached to the USB port.

# Installation:

There is an bash script called 'Install-cd-rip.sh' that installs the required programs and creates the required links for moOde.

The required programs are:
  cd-discid
  eject
  flock
  touch
  truncate
  mpc
  mpd
  cdparanoia
  lame
  glyrc
  eyeD3

# Configuration:

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


# Usage:

  Insert the CD into the drive. The CD will be checked to see if it has been previously ripped. If not, the ripping process will take about 12 minutes. After this, the CD will be ejected and moOde will play the ripped files. If the CD has been previously ripped, it will be ejected and moOde will play the ripped files. More CDs can be inserted for batch queueing.
