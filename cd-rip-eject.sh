#!/bin/bash
#
##################################################################
##################################################################
##################################################################
#
# Do not change anything from here on.
#
##################################################################
##################################################################
##################################################################

# (c) 2020 - TheMetalHead - https://github.com/TheMetalHead/moOde-CD-Rip-and-Play
#
# TheMetalHead/moOde-CD-Rip-and-Play is licensed under the GNU General Public License v3.0
#
# Permissions of this strong copyleft license are conditioned on making available complete
# source code of licensed works and modifications, which include larger works using a
# licensed work, under the same license. Copyright and license notices must be preserved.
# Contributors provide an express grant of patent rights.
#
# A copy of the license can be found in: LICENSE
#
#
# Permissions:
#       Commercial use
#       Modification
#       Distribution
#       Patent use
#       Private use
#
# Limitations:
#       Liability
#       Warranty
#
# Conditions:
#       License and copyright notice
#       State changes
#       Disclose source
#       Same license



##################################################################
# The software version.
##################################################################

readonly	_SW_VERSION="1.0"

##################################################################
# Work out the CDROM path. Must have no trailing slash.
##################################################################

CDROM="/dev/cdrom"

# If the cdrom does not exist.
if [ ! -e "${CDROM}" ]; then
	CDROM=""
	CDPATH="/dev/sr"

	if [ -e "${CDPATH}"0 ]; then
		CDROM="${CDPATH}"0
	fi

	if [ -e "${CDPATH}"1 ]; then
		CDROM="${CDPATH}"1
	fi
fi

# If the string is not empty.
if [ -n "${CDROM}" ]; then
	/usr/bin/eject "${CDROM}"
fi
