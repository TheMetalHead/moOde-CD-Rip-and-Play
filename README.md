# moOde-CD-Rip-and-Play
Moode CD rip and play

A program to optionally rip a new CD and play it if it has been ripped.

Requirements:

  A working moOde image (v6.5.0 or better) on a Raspberry Pi3 . (Rpi4 not tested).
  A CD drive attached to the USB port.

CDs that have already been ripped can be batch queued.

There is an installation script 'Install-cd-rip.sh' that creates the required links for moOde.

Edit the configuration file as required: cd-rip-and-or-play.conf

Usage:
  Insert the CD into the drive.

  If the CD is being ripped, this will take about 12 minutes. After this, the CD will be ejected and moOde will play the ripped files.

  If the CD has already been ripped, moOde will eject the CD and play the ripped files after a few seconds.
