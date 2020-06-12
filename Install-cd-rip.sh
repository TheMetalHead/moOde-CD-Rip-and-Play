#!/bin/bash
#
# Install the CD ripper software for 'moOde'.
#
# Edit the CD rip configuration file as required.
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
#	Commercial use
#	Modification
#	Distribution
#	Patent use
#	Private use
#
# Limitations:
#	Liability
#	Warranty
#
# Conditions:
#	License and copyright notice
#	State changes
#	Disclose source
#	Same license



##################################################################
# Work out this files name, path and config pathname.
##################################################################

# Returns full path and name of this script.
# /home/pi/Src/cd-rip/cd-rip-and-or-play.sh
readonly	FULLPATHNAME=$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null||echo "$0")

# The directory where this script resides.
# /home/pi/Src/cd-rip
readonly	DIRECTORY=$(dirname "${FULLPATHNAME}")

readonly	CD_RIP_AND_OR_PLAY="cd-rip-and-or-play"

# The file with the list of cd genres to re-map to abcde genres.
readonly	GENRES_FILE_TO_CONVERT="genres-to-convert"

readonly	CDRIP_CONFIG="${CD_RIP_AND_OR_PLAY}.conf"

readonly	UDEV_RULE="99-srX.rules"

readonly	SYSTEMD_EJECT_SERVICE="cd-rip-eject.service"

readonly	SYSTEMD_RIP_SERVICE="${CD_RIP_AND_OR_PLAY}.service"



##################################################################
# Colour constants.
##################################################################

# Reset
Colour_Off='\033[0m'      # Text Reset

# Regular Colours
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White

# Bold
BBlack='\033[1;30m'       # Black
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BYellow='\033[1;33m'      # Yellow
BBlue='\033[1;34m'        # Blue
BPurple='\033[1;35m'      # Purple
BCyan='\033[1;36m'        # Cyan
BWhite='\033[1;37m'       # White

# Underline
UBlack='\033[4;30m'       # Black
URed='\033[4;31m'         # Red
UGreen='\033[4;32m'       # Green
UYellow='\033[4;33m'      # Yellow
UBlue='\033[4;34m'        # Blue
UPurple='\033[4;35m'      # Purple
UCyan='\033[4;36m'        # Cyan
UWhite='\033[4;37m'       # White

# Background
On_Black='\033[40m'       # Black
On_Red='\033[41m'         # Red
On_Green='\033[42m'       # Green
On_Yellow='\033[43m'      # Yellow
On_Blue='\033[44m'        # Blue
On_Purple='\033[45m'      # Purple
On_Cyan='\033[46m'        # Cyan
On_White='\033[47m'       # White

# High Intensity
IBlack='\033[0;90m'       # Black
IRed='\033[0;91m'         # Red
IGreen='\033[0;92m'       # Green
IYellow='\033[0;93m'      # Yellow
IBlue='\033[0;94m'        # Blue
IPurple='\033[0;95m'      # Purple
ICyan='\033[0;96m'        # Cyan
IWhite='\033[0;97m'       # White

# Bold High Intensity
BIBlack='\033[1;90m'      # Black
BIRed='\033[1;91m'        # Red
BIGreen='\033[1;92m'      # Green
BIYellow='\033[1;93m'     # Yellow
BIBlue='\033[1;94m'       # Blue
BIPurple='\033[1;95m'     # Purple
BICyan='\033[1;96m'       # Cyan
BIWhite='\033[1;97m'      # White

# High Intensity backgrounds
On_IBlack='\033[0;100m'   # Black
On_IRed='\033[0;101m'     # Red
On_IGreen='\033[0;102m'   # Green
On_IYellow='\033[0;103m'  # Yellow
On_IBlue='\033[0;104m'    # Blue
On_IPurple='\033[0;105m'  # Purple
On_ICyan='\033[0;106m'    # Cyan
On_IWhite='\033[0;107m'   # White



##################################################################
# Import the 'cd-rip-and-or-play.conf' configuration file.
##################################################################

source	"${DIRECTORY}/${CDRIP_CONFIG}" || { echo "ERROR: in configuration file: ${DIRECTORY}/${CDRIP_CONFIG}"; exit 1; }



##################################################################
# Utility functions.
##################################################################

# This is used to suppress all text output.
#
# Returns 0 on success else 1 on error.
#
_cd_func() {
	# If argument supplied.
	if [[ -n "${1}" ]]; then
		# Suppress all text output.
		cd "${1}" 2>&1 && return 0
	fi

	return 1
}



_exit_trap() {
#	cd "${OLD_DIR}"
	_cd_func "${OLD_DIR}"
}



_display_ok() {
	echo -e "${Black}${On_Green}[ OK ]${Colour_Off}"
}



# Usage:	_exit_error	Exit_Code	Message_To_display
#
_exit_error() {
	local	_EXIT_CODE

	_EXIT_CODE="$1"

	shift

	echo -e "${BWhite}${On_Red}[ FATAL ]   ${FUNCNAME[1]} : Line ${BASH_LINENO[0]} : Exit ${_EXIT_CODE} - ${*}${Colour_Off}"

	exit "${_EXIT_CODE}"
}



# Tests for a non zero result code and outputs to the log file and exits.
# It outputs the function name, line number, message and command result code.
#
# Usage:	_check_command_and_exit_if_error	Last_Result_Code	Exit_Code	Message_To_Display
#
_check_command_and_exit_if_error() {
	local	_LAST_RESULT

	_LAST_RESULT="$1"

	if [ 0 -ne "${_LAST_RESULT}" ]; then
		local	_EXIT_CODE

		_EXIT_CODE="$2"

		shift
		shift

		echo -e "${BWhite}${On_Red}[ FATAL ]   ${FUNCNAME[1]} : Line ${BASH_LINENO[0]} : Exit ${_EXIT_CODE} - Command returned error code: ${_LAST_RESULT} - ${*}${Colour_Off}"

		exit "${_EXIT_CODE}"
	fi
}



# Prompts the user to enter Yes or No and returns 1 if YES else 0 if NO.
#
# Usage: _get_yes_no <Optional prompt>
#
_get_yes_no() {
	local	_PROMPT
	local	_RESPONSE

	if [ "$1" ]; then
		_PROMPT="$1"
	else
		_PROMPT="Are you sure"
	fi

	_PROMPT="${_PROMPT} [y/n] ?"

	# Loop forever until the user enters a valid response (Y/N or Yes/No).
	while true; do
		read -r -p "$(echo -e "${BWhite}${_PROMPT}${Colour_Off}") " _RESPONSE

		case "${_RESPONSE}" in
			[Yy][Ee][Ss]|[Yy])	# Yes or Y (case-insensitive)
				return 1
				;;
			[Nn][Oo]|[Nn])		# No or N (case-insensitive)
				return 0
				;;
			*)			# Anything else including a blank is invalid
				;;
		esac
	done
}



# Usage:	_abort_on_trailing_slash	Path_to_check	Variable_name
#
_abort_on_trailing_slash() {
	if [[ "/" == "${1: -1}" ]]; then
		_exit_error 2 "Cannot have a trailing slash: ${2} -> ${1}"
	fi
}



# Usage:	_abort_on_leading_or_trailing_slash	Path_to_check	Variable_name
#
_abort_on_leading_or_trailing_slash() {
#	if [[ "/" == "${1:0:1}" ]]; then

	if [[ "/" == "${1%"${1#?}"}" ]]; then
		_exit_error 3 "Cannot have a leading slash: ${2} -> ${1}"
	fi

	_abort_on_trailing_slash "${1}" "${2}"
}



check_config_file() {
	_abort_on_leading_or_trailing_slash "${LIBRARY_TAG}" LIBRARY_TAG

	_abort_on_leading_or_trailing_slash "${MUSIC_MNT_SOURCE}" MUSIC_MNT_SOURCE

	# If not empty empty.
	if [[ -n "${MUSIC_SUB_DIR}" ]]; then
		_abort_on_leading_or_trailing_slash "${MUSIC_SUB_DIR}" MUSIC_SUB_DIR
	fi

	_abort_on_trailing_slash "${TEMP_DIR}" TEMP_DIR

	if [[ "${DEFAULT_VOLUME}" -lt 0 ]]; then
		_exit_error 4 "Default volume cannot be less than 0: DEFAULT_VOLUME -> ${DEFAULT_VOLUME}"
	fi

	if [[ "${DEFAULT_VOLUME}" -gt 35 ]]; then
		_exit_error 5 "Default volume cannot be greater than 35: DEFAULT_VOLUME -> ${DEFAULT_VOLUME}"
	fi

	_abort_on_leading_or_trailing_slash "${DEFAULT_SAVED_USER_PLAYLIST}" DEFAULT_SAVED_USER_PLAYLIST
	_abort_on_leading_or_trailing_slash "${DEFAULT_SAVED_USER_PLAYLIST_EXTENSION}" DEFAULT_SAVED_USER_PLAYLIST_EXTENSION
}



##################################################################
##################################################################
##################################################################
#
# The start of the installation program.
#
##################################################################
##################################################################
##################################################################

# Ensure we are root. If not, restart it.
#
if [[ 0 != "$EUID" ]]; then
	# Restart the script as root.
	sudo "$0" "$@"

	exit "${?}"
fi

# We are root.



HILITE="${BCyan}"

echo ""
echo -e "Install the cd ripper software from files in this directory for use with ${HILITE}'moOde'${Colour_Off}."

if [ ! -f "/var/www/command/moode.php" ]; then
	echo ""
	echo -e "${BYellow}This is not a 'moOde' installation.${Colour_Off}"
	echo ""
	echo -e "${BYellow}Aborted...${Colour_Off}"

	exit 6
fi



# Save our current directory.
OLD_DIR=$(pwd)

# Change to the directory where this script is located.
_cd_func "${DIRECTORY}"

# This should never happen.
_check_command_and_exit_if_error "${?}" 7 "Cannot change directory to: ${DIRECTORY}"



##################################################################
# Install our traps.
##################################################################

trap	_exit_trap	EXIT ERR SIGHUP SIGINT SIGQUIT SIGABRT SIGTERM



##################################################################
# Search for the cdrom drive.
##################################################################

# Find out which device the CDROM appears as.
CDROM="/dev/cdrom"

# If the cdrom does not exist.
if [[ ! -e "${CDROM}" ]]; then
	# If not found.
	CDROM=""
	CDPATH="/dev/sr"

	if [[ -e "${CDPATH}0" ]]; then
		CDROM="${CDPATH}0"
	fi

	if [[ -e "${CDPATH}1" ]]; then
		CDROM="${CDPATH}1"
	fi
fi



##################################################################
# Output some details.
##################################################################

if [[ "${*}" ]]; then
	echo "args -> ${*}"

	_exit_error 8 "Arguments are not required: ${*}"
fi

if [[ -z "${CDROM}" ]]; then
	_exit_error 9 "Cannot find a cdrom drive."
fi

echo ""
echo "Ensure that the configuration file is correct for your requirements."
echo ""
echo -e "Reading the configuration file: ${HILITE}${DIRECTORY}/${CDRIP_CONFIG}${Colour_Off}"
echo ""
echo -e "Found CDROM drive:       ${HILITE}${CDROM}${Colour_Off}"
echo ""
echo -e "Music home path:         ${HILITE}${MUSIC_HOME_PATH}${Colour_Off}"		# Do not add any trailing slashes. Full path
echo -e "Ripped music dir:        ${HILITE}${RIPPED_MUSIC_DIR}${Colour_Off}"		# Do not add any leading/trailing slashes
echo -e "Ripped music sub dir:    ${HILITE}${MUSIC_SUB_DIR}${Colour_Off}"
echo ""
echo -e "Owner:                   ${HILITE}${RIPPED_MUSIC_OWNER}${Colour_Off}"		# WARNING: The owner existance is not checked
echo -e "Saved playlist name:     ${HILITE}${DEFAULT_SAVED_USER_PLAYLIST}${DEFAULT_SAVED_USER_PLAYLIST_EXTENSION}${Colour_Off}"
echo -e "Default volume:          ${HILITE}${DEFAULT_VOLUME}${Colour_Off}"		# Default 'moOde' volume
echo -e "Library name in 'moOde': ${HILITE}${LIBRARY_TAG}${Colour_Off}"
echo ""
echo -e "Music storage path:      ${HILITE}${MUSIC_HOME_PATH}/${RIPPED_MUSIC_DIR}/${MUSIC_SUB_DIR}${Colour_Off}"

# Do not add any leading/trailing slashes for the music source.
echo ""
echo -e "This will appear in the 'moOde Library Folder' panel as: ${HILITE}${LIBRARY_TAG}${Colour_Off}"
echo ""



check_config_file



##################################################################
#
##################################################################

# For some reason '_get_yes_no()' changes the working directory.
# In fact, any function call will changes the working directory.
# WHY? WHY? WHY? WHY? WHY?
#
# This is a hack...
pushd "." > /dev/null				# Save the current directory on the stack and change to "."

# Returns 1 if YES else 0 if NO.
_get_yes_no "Continue"

RV="${?}"

# This is a hack...
popd > /dev/null				# Restore the save directory from the stack.

if [[ 0 -eq "${RV}" ]]; then
	# No
	echo -e "${BYellow}Aborted...${Colour_Off}"

	exit 10
fi

echo ""
echo "-------------------------------------------------------------------------------------------------"



##################################################################
# Check that all our files for the cd ripper exist and set the owners and file mode.
##################################################################

echo ""
echo "Checking our files exist and set the owners and file mode."

for FILE_TO_CHECK in "${UDEV_RULE}",444 "${SYSTEMD_EJECT_SERVICE}",444 "${SYSTEMD_RIP_SERVICE}",444 \
			"${GENRES_FILE_TO_CONVERT}",444 "abcde.conf",644 "cd-rip-and-or-play",644 \
			"cd-rip-and-or-play.sh",544 "${CDRIP_CONFIG}",644 "cd-rip-eject.sh",544 \
			 "Install-cd-rip.sh",544 "Remove-cd-rip.sh",544
do
	_FILE=${FILE_TO_CHECK%,*}
	_MOD=${FILE_TO_CHECK#*,}

	# If the file does not exist.
	if [ ! -e "${_FILE}" ]; then
		_exit_error 11 "CD ripper file does not exist: ${DIRECTORY}/${_FILE}"
	fi

	chown "${RIPPED_MUSIC_OWNER}" "${_FILE}"

	_check_command_and_exit_if_error "${?}" 12 "Cannot change owner of file: ${_FILE} to: ${RIPPED_MUSIC_OWNER}"

	chmod "${_MOD}" "${_FILE}"

	_check_command_and_exit_if_error "${?}" 13 "Cannot change file mode of: ${_FILE} to: ${_MOD}"
done

_display_ok



##################################################################
# Look for the mount directory.
##################################################################

echo "Checking for: /mnt"

# If the mount directory does not exist.
if [[ ! -d "/mnt" ]]; then
	_exit_error 14 "Cannot find directory: /mnt"
fi

_display_ok



##################################################################
# Install the required programs.
##################################################################

echo "Checking for the required programs."

MISSING_PROGRAMS=()

for CMD in "abcde" "cd-discid" "eject" "flock" "touch" "truncate" "mpc" "mpd" "cdparanoia" "lame" "flac" "mpcenc" "glyrc" "eyeD3"
do
	# Check if the command exists and is executable.
	CMD_TO_CHECK=$(command -v "${CMD}")

	# If the command is not found, add it to the missing list to install later on.
	if [ -z "${CMD_TO_CHECK}" ]; then
		# HACK - HACK - HACK - HACK - HACK - HACK
		# 'eyeD3' is actually 'eyed3' in apt.
		# 'mpcenc' is actually 'musepack-tools' in apt.
		if [ "eyeD3" == "${CMD}" ]; then
			MISSING_PROGRAMS+=("eyed3")
		else
			if [ "mpcenc" == "${CMD}" ]; then
				MISSING_PROGRAMS+=("musepack-tools")
			else
				MISSING_PROGRAMS+=("${CMD}")
			fi
		fi
	fi
done

if [[ -n "${MISSING_PROGRAMS[*]}" ]]; then
	echo "The following programs need to be installed: ${MISSING_PROGRAMS[*]}"
	echo "Updating the package repository."

	apt update

	_check_command_and_exit_if_error "${?}" 15 "Apt package repository update failed."

	echo "Installing the missing programs."

	apt install "${MISSING_PROGRAMS[@]}"

	_check_command_and_exit_if_error "${?}" 16 "Installation of missing programs failed."
fi

_display_ok



##################################################################
# Read '/etc/mpd.conf' and look at what 'music_directory' points to.
##################################################################

echo "Looking in '/etc/mpd.conf' for the music directory."

MPD_MUSIC_DIR=""

# Read the file in row mode and extract each line.
while IFS= read -r LINE; do
	#  music_directory      "/var/lib/mpd/music"
	_KEY=${LINE% *}
	_VALUE=${LINE##* }

	if [ "${_KEY}" == "music_directory" ]; then
		# Remove the " character from the start and end of the value token.
		_VALUE=${_VALUE#\"}
		_VALUE=${_VALUE%\"}

		# Returns: /var/lib/mpd/music
		MPD_MUSIC_DIR="${_VALUE}"

		echo "Got: ${MPD_MUSIC_DIR}"

		break
	fi
done < "/etc/mpd.conf"

if [[ -z "${MPD_MUSIC_DIR}" ]]; then
	_exit_error 17 "Cannot find 'music_directory' entry in '/etc/mpd.conf'"
fi

# If the directory does not exist.
if [[ ! -d "${MPD_MUSIC_DIR}" ]]; then
	_exit_error 18 "Cannot find directory: ${MPD_MUSIC_DIR}"
fi

_display_ok



##################################################################
# Create the music cd directory if required.
##################################################################

# /home/pi/Music-CD
MY_MUSIC_CD_DIR="${MUSIC_HOME_PATH}/${RIPPED_MUSIC_DIR}"

echo "Checking for the cd music storage directory: ${MY_MUSIC_CD_DIR}"

# If the directory does not exist.
if [[ ! -d "${MY_MUSIC_CD_DIR}" ]]; then
	echo "Creating the cd music storage directory: ${MY_MUSIC_CD_DIR}"

	mkdir "${MY_MUSIC_CD_DIR}"

	_check_command_and_exit_if_error "${?}" 19 "Cannot make directory: ${MY_MUSIC_CD_DIR}"

	chown "${RIPPED_MUSIC_OWNER}" "${MY_MUSIC_CD_DIR}"

	_check_command_and_exit_if_error "${?}" 20 "Cannot change owner for: ${MY_MUSIC_CD_DIR}"

	# If the directory still does not exist.
	if [[ ! -d "${MY_MUSIC_CD_DIR}" ]]; then
		_exit_error 25 "Cannot find directory: ${MY_MUSIC_CD_DIR}"
	fi
fi

_display_ok



##################################################################
# Create the music cd sub directory if required.
##################################################################

# /home/pi/Music-CD/${MUSIC_CD_SUB_DIR}

# If not empty.
if [[ -n "${MUSIC_SUB_DIR}" ]]; then
	SUB_DIR="${MY_MUSIC_CD_DIR}/${MUSIC_SUB_DIR}"

	echo "Checking for the cd music storage directory: ${SUB_DIR}"

	# If the sub-directory does not exist.
	if [[ ! -d "${SUB_DIR}" ]]; then
		echo "Creating the cd music storage sub-directory: ${SUB_DIR}"

		mkdir "${SUB_DIR}"

		_check_command_and_exit_if_error "${?}" 21 "Cannot make directory: ${MUSIC_SUB_DIR}"

		chown "${RIPPED_MUSIC_OWNER}" "${SUB_DIR}"

		_check_command_and_exit_if_error "${?}" 22 "Cannot change owner for: ${MUSIC_SUB_DIR}"

		# If the directory still does not exist.
		if [[ ! -d "${SUB_DIR}" ]]; then
			_exit_error 23 "Cannot find directory: ${SUB_DIR}"
		fi
	fi

	MY_MUSIC_CD_DIR="${SUB_DIR}"

	_display_ok
fi



##################################################################
# Create the disc id ripped directory if required.
##################################################################

# ${MY_MUSIC_CD_DIR}/.Music CDs ripped
readonly	DISCID_DIR="${MY_MUSIC_CD_DIR}/.Music CDs Ripped"

echo "Checking for the cd ripped id directory: ${DISCID_DIR}"

# If the disc id directory does not exist, create it.
if [ ! -d "${DISCID_DIR}" ]; then
	echo "Creating '${DISCID_DIR}' directory."

	mkdir "${DISCID_DIR}"

	_check_command_and_exit_if_error "${?}" 24 "Cannot make directory: ${DISCID_DIR}"

	chown "${RIPPED_MUSIC_OWNER}" "${DISCID_DIR}"

	_check_command_and_exit_if_error "${?}" 25 "Cannot change owner for: ${DISCID_DIR}"

	# If the directory still does not exist.
	if [[ ! -d "${DISCID_DIR}" ]]; then
		_exit_error 26"Cannot find directory: ${DISCID_DIR}"
	fi

	README_FILE="${DISCID_DIR}/README.txt"

	echo "This directory contains the list of ripped CDs." > "${README_FILE}"
	echo "Do not delete it otherwise the CD will be ripped again the next time it is inserted." >> "${README_FILE}"

	chown "${RIPPED_MUSIC_OWNER}" "${README_FILE}"

	_check_command_and_exit_if_error "${?}" 27 "Cannot change owner for: ${README_FILE}"

	# If the file does not exist or is empty.
	if [[ ! -s "${README_FILE}" ]]; then
		_exit_error 28 "Cannot create the readme file: ${README_FILE}"
	fi
fi

_display_ok



##################################################################
# Create a 'CD' link to your CD music directory.
##################################################################

echo "Changing directory to: /mnt"

# cd "/mnt"
_cd_func "/mnt"

_check_command_and_exit_if_error "${?}" 29 "Cannot change directory to: /mnt"

# /mnt/CD
MNT_CD="/mnt/${MUSIC_MNT_SOURCE}"

echo "Checking for link: ${MNT_CD} to ${MY_MUSIC_CD_DIR}"

# -d FILE: True if file is a directory.
# -h FILE: True if file is a symbolic link.

if [[ -d "${MNT_CD}" || -h "${MNT_CD}" ]]; then
	# Do nothing.
	:
else
	# CD /home/pi/Music-CD
	echo "Creating link: '${MUSIC_MNT_SOURCE}' to: '${MY_MUSIC_CD_DIR}'"

	# If the target does not exist.
	# ln -s -T "/home/pi/Music-CD" "CD"
	ln -s -T "${MY_MUSIC_CD_DIR}" "${MUSIC_MNT_SOURCE}"

	_check_command_and_exit_if_error "${?}" 30 "Cannot create link to: ${MY_MUSIC_CD_DIR}"

	# If the directory still does not exist.
	if [[ ! -d "${MNT_CD}" ]]; then
		_exit_error 31 "Cannot find target: ${MNT_CD}"
	fi
fi

_display_ok



##################################################################
# Create a symbolic link to the mount point directory.
##################################################################

# /var/lib/mpd/music
echo "Changing directory to: ${MPD_MUSIC_DIR}"

# cd "${MPD_MUSIC_DIR}"
_cd_func "${MPD_MUSIC_DIR}"

_check_command_and_exit_if_error "${?}" 32 "Cannot change directory to: ${MPD_MUSIC_DIR}"

echo "Checking for link: ${LIBRARY_TAG} to: ${MNT_CD}"

# /mnt/${MUSIC_MNT_SOURCE}
# /mnt/CD
#
# If the symbolic link does not exist.
#if [[ ! -h "${LIBRARY_TAG}" ]]; then
if [[ ! -L "${LIBRARY_TAG}" ]]; then
	echo "Creating link: '${LIBRARY_TAG}' to: '${MNT_CD}'"

	ln -s "${MNT_CD}" "${LIBRARY_TAG}"

	_check_command_and_exit_if_error "${?}" 33 "Cannot create link to: ${MNT_CD}"
fi

_display_ok



##################################################################
# Check for access to the music directory.
##################################################################

# If the directory where the ripped CD files will be stored cannot be accessed.

# /var/lib/mpd/music/CD
RIPPING_DIR="${MPD_MUSIC_DIR}/${LIBRARY_TAG}"

echo "Checking for: ${RIPPING_DIR}"

# /var/lib/mpd/music/CD
if [[ ! -d "${RIPPING_DIR}" ]]; then
	_exit_error 34 "Cannot find directory: ${RIPPING_DIR}"
fi

_display_ok



##################################################################
# Create the 'udev' and 'systemd' entries.
##################################################################

echo "Checking for installed udev file."

# cd "/etc/udev/rules.d"
_cd_func "/etc/udev/rules.d"

_check_command_and_exit_if_error "${?}" 35 "Cannot change directory to: /etc/udev/rules.d"

# If the file exists and is a symbolic link.
if [[ -L "${UDEV_RULE}" ]]; then
	echo "Udev rules link already exists to: ${DIRECTORY}/${UDEV_RULE}"
else
	# /home/pi/Src/cd-rip/99-srX.rules
	echo "Creating udev link to: '${DIRECTORY}/${UDEV_RULE}'"

	ln -s "${DIRECTORY}/${UDEV_RULE}" "."

	_check_command_and_exit_if_error "${?}" 36 "Cannot create udev rule link to: ${DIRECTORY}/${UDEV_RULE}"
fi

_display_ok

echo "Checking for installed systemd files."

# cd "/etc/systemd/system"
_cd_func "/etc/systemd/system"

_check_command_and_exit_if_error "${?}" 37 "Cannot change directory to: /etc/systemd/system"

# If the file exists and is a symbolic link.
if [[ -L "${SYSTEMD_RIP_SERVICE}" ]]; then
	echo "Systemd link already exists to: ${SYSTEMD_RIP_SERVICE}"
else
	# /home/pi/Src/cd-rip/cd-rip-and-or-play.service
	echo "Creating systemd link to: '${DIRECTORY}/${SYSTEMD_RIP_SERVICE}'"

	ln -s "${DIRECTORY}/${SYSTEMD_RIP_SERVICE}" "."

	_check_command_and_exit_if_error "${?}" 38 "Cannot create systemd link to: ${DIRECTORY}/${SYSTEMD_RIP_SERVICE}"
fi

# If the file exists and is a symbolic link.
if [[ -L "${SYSTEMD_EJECT_SERVICE}" ]]; then
	echo "Systemd link already exists to: ${SYSTEMD_EJECT_SERVICE}"
else
	# /home/pi/Src/cd-rip/cd-rip-eject.service
	echo "Creating systemd link to: '${DIRECTORY}/${SYSTEMD_EJECT_SERVICE}'"

	ln -s "${DIRECTORY}/${SYSTEMD_EJECT_SERVICE}" "."

	_check_command_and_exit_if_error "${?}" 39 "Cannot create systemd link to: ${DIRECTORY}/${SYSTEMD_EJECT_SERVICE}"
fi

_display_ok



##################################################################
# Create the log rotate entry.
##################################################################

echo "Checking for installed logrotate file."

# cd "/etc/logrotate.d"
_cd_func "/etc/logrotate.d"

_check_command_and_exit_if_error "${?}" 40 "Cannot change directory to: /etc/logrotate.d"

# If the file exists and is a symbolic link.
if [[ -L "${CD_RIP_AND_OR_PLAY}" ]]; then
	echo "Logrotate link already exists to: ${DIRECTORY}/${CD_RIP_AND_OR_PLAY}"
else
	# /home/pi/Src/cd-rip/cd-rip-and-or-play
	echo "Creating logrotate link to: '${DIRECTORY}/${CD_RIP_AND_OR_PLAY}'"

	ln -s "${DIRECTORY}/${CD_RIP_AND_OR_PLAY}" "."

	_check_command_and_exit_if_error "${?}" 41 "Cannot create udev rule link to: ${DIRECTORY}/${CD_RIP_AND_OR_PLAY}"

	chown "root:root" "${CD_RIP_AND_OR_PLAY}"

	_check_command_and_exit_if_error "${?}" 42 "Cannot change owner of file: ${CD_RIP_AND_OR_PLAY}"

	chmod 644 "${CD_RIP_AND_OR_PLAY}"

	_check_command_and_exit_if_error "${?}" 43 "Cannot change file mode of: ${CD_RIP_AND_OR_PLAY} to: 644"
fi

_display_ok



##################################################################
# Tell mpd about the new cd music directory.
##################################################################

echo "Updating mpd with the new music directory: ${LIBRARY_TAG}"
echo ""

mpc update

_check_command_and_exit_if_error "${?}" 44 "Cannot get mpd to update the music directory: ${LIBRARY_TAG}"



##################################################################
# Remove our traps.
##################################################################

trap	-	EXIT ERR SIGHUP SIGINT SIGQUIT SIGABRT SIGTERM



##################################################################
# All done.
##################################################################

echo ""
echo -e "${Black}${On_Green}SUCCESS:${Colour_Off} CD ripper/player for ${HILITE}'moOde'${Colour_Off} installed ok."
echo -e "${HILITE}'moOde'${Colour_Off} can be accessed on ip address: ${HILITE}$(hostname -I)${Colour_Off}"

exit 0
