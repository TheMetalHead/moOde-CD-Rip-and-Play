# moOde-CD-Rip-and-Play
MoOde CD rip and play

A companion program for moOde (http://moodeaudio.org/) to rip CDs and play them.

Requirements:

  A working moOde image (tested on v6.5.0) on a Raspberry Pi3 . (Rpi4 not tested).
  An external CD drive attached to the USB port.

CDs that have already been ripped can be batch queued.

There is an installation script 'Install-cd-rip.sh' that creates the required links for moOde.

Edit the configuration file as required: cd-rip-and-or-play.conf

Usage:
  Insert the CD into the drive. The CD will be checked to see if it has been previously ripped. If not, the rippinf process will take about 12 minutes. After this, the CD will be ejected and moOde will play the ripped files. If the CD has been previously ripped, it will be ejected and moOde will play the ripped files.

