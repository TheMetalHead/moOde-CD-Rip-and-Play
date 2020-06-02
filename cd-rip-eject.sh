#!/bin/bash
#
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
