#!/bin/bash
#
# Update the CD ripper software for 'moOde'.
#
# Leaves the existing CD rip configuration file unchanged.
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

readonly	UPDATE_REPO="https://github.com/TheMetalHead/moOde-CD-Rip-and-Play"

readonly	UPDATE_ZIP_FILE="moOde-CD-Rip-and-Play.zip"

readonly	CD_RIP_AND_OR_PLAY="cd-rip-and-or-play"

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



###################################################################
## Import the 'cd-rip-and-or-play.conf' configuration file.
###################################################################
#
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



##################################################################
##################################################################
##################################################################
#
# The start of the updating program.
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
echo -e "Update the cd ripper software for use with ${HILITE}'moOde'${Colour_Off}."

if [ ! -f "/var/www/command/moode.php" ]; then
	echo ""
	echo -e "${BYellow}This is not a 'moOde' installation.${Colour_Off}"
	echo ""
	echo -e "${BYellow}Aborted...${Colour_Off}"

	exit 2
fi



# Save our current directory.
OLD_DIR=$(pwd)

# Change to the directory where this script is located.
_cd_func "${DIRECTORY}"

# This should never happen.
_check_command_and_exit_if_error "${?}" 3 "Cannot change directory to: ${DIRECTORY}"



##################################################################
# Install our traps.
##################################################################

trap	_exit_trap	EXIT ERR SIGHUP SIGINT SIGQUIT SIGABRT SIGTERM



##################################################################
# Output some details.
##################################################################

if [[ "${*}" ]]; then
	echo "args -> ${*}"

	_exit_error 4 "Arguments are not required: ${*}"
fi

echo ""
echo "Creates a backup and leaves the existing CD rip configuration file: ${CDRIP_CONFIG} unchanged."
echo ""
echo -e "Reading the configuration file: ${HILITE}${DIRECTORY}/${CDRIP_CONFIG}${Colour_Off}"
echo ""
echo -e "Owner: ${HILITE}${RIPPED_MUSIC_OWNER}${Colour_Off}"		# WARNING: The owner existance is not checked
echo ""



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

	exit 5
fi

echo ""
echo "-------------------------------------------------------------------------------------------------"



##################################################################
# Check that all our files for the cd ripper exist.
##################################################################

echo ""
echo "Checking our files exist."

for _FILE in "${UDEV_RULE}" "${SYSTEMD_EJECT_SERVICE}" "${SYSTEMD_RIP_SERVICE}" "abcde.conf" "${CD_RIP_AND_OR_PLAY}" \
		"cd-rip-and-or-play.sh" "${CDRIP_CONFIG}" "cd-rip-eject.sh" "Install-cd-rip.sh" "Remove-cd-rip.sh"
do
	# If the file does not exist.
	if [ ! -e "${_FILE}" ]; then
		_exit_error 6 "CD ripper file does not exist: ${DIRECTORY}/${_FILE}"
	fi
done

_display_ok



##################################################################
# Check that we have the unzip program.
##################################################################

# Check if the unzip command exists and is executable.
CMD_TO_CHECK=$(command -v unzip)

# If the command is not found, install it.
if [ -z "${CMD_TO_CHECK}" ]; then
        echo "Installing the required 'unzip' program."
        echo "Updating the package repository."

        apt update

        _check_command_and_exit_if_error "${?}" 7 "Apt package repository update failed."

        echo "Installing the missing program."

        apt install unzip

        _check_command_and_exit_if_error "${?}" 8 "Installation of missing program failed."

	_display_ok
fi


##################################################################
# Ensure that we are not ripping a cd.
##################################################################

$(ps -e | grep -q -i "${CD_RIP_AND_OR_PLAY}")

# If found that the ripper is running.
if [ "0" -eq "${?}" ]; then
	_exit_error 9 "Cannot perform the update whilst the cd ripping is in progress."
fi



##################################################################
# Grab the update file from the repository.
##################################################################

echo "Grabbing the update file from: ${UPDATE_REPO}"

wget -q "${UPDATE_REPO}/archive/master.zip" -O "${UPDATE_ZIP_FILE}"

_check_command_and_exit_if_error "${?}" 10 "Cannot grab update file."

_display_ok



##################################################################
# Make a backup directory.
##################################################################

# Backup - 2020-06-08 - 14-23-49
BACKUP_DIR="Backup - $(date '+%Y-%m-%d - %H-%M-%S')"

echo "Creating the backup directory: ${BACKUP_DIR}"

mkdir "${BACKUP_DIR}"

_check_command_and_exit_if_error "${?}" 11 "Cannot make the backup directory: ${BACKUP_DIR}"

chown "${RIPPED_MUSIC_OWNER}" "${BACKUP_DIR}"

_check_command_and_exit_if_error "${?}" 12 "Cannot change the owner for: ${BACKUP_DIR}"

# If the directory still does not exist. Should not happen.
if [[ ! -d "${BACKUP_DIR}" ]]; then
	_exit_error 13 "Cannot find the backup directory: ${BACKUP_DIR}"
fi

_display_ok



##################################################################
# Copy files to the backup directory.
##################################################################

echo "Backing up the files to: ${BACKUP_DIR}"
wcho "Does not backup any sub-directories."

find * -maxdepth 0 -type f -exec cp -p '{}' -t "${BACKUP_DIR}" \;

_check_command_and_exit_if_error "${?}" 14 "Cannot backup the files to: ${BACKUP_DIR}"

_display_ok



##################################################################
# Delete the old files but not any sub-directories.
##################################################################

echo "Deleting the old files."

for _FILE in *; do
	# If the file exists and is a regular file, as opposed to a directory, a device special file or a link.
	if [[ -f "${_FILE}" ]]; then
		if [[ "${UPDATE_ZIP_FILE}" != "${_FILE}" ]]; then
			echo -e "\tFile: ${_FILE}"

			rm -f  "${_FILE}"

			_check_command_and_exit_if_error "${?}" 15 "Cannot delete file: ${_FILE}"
		fi
	fi
done

_display_ok



##################################################################
# Perform the update.
##################################################################

echo "Performing the update."

unzip -j "${UPDATE_ZIP_FILE}"

_check_command_and_exit_if_error "${?}" 16 "Cannot unzip the update file: ${UPDATE_ZIP_FILE}"

chmod 544 *.sh

_check_command_and_exit_if_error "${?}" 17 "Cannot change the mode of the update file to 544: ${UPDATE_ZIP_FILE}"

_display_ok



##################################################################
# Restore the configuration file.
##################################################################

echo "Restoring the configuration file from: ${BACKUP_DIR}/cd-rip-and-or-play.conf"

cp -f -p "${BACKUP_DIR}/cd-rip-and-or-play.conf" "cd-rip-and-or-play.conf"

_check_command_and_exit_if_error "${?}" 18 "Cannot restore the configuration file: ${${BACKUP_DIR}/cd-rip-and-or-play.conf"

_display_ok



##################################################################
# Changing the owner of the new files.
##################################################################

echo "Changing the owner of the updated files."

for _FILE in *; do
	# If the file exists and is a regular file, as opposed to a directory, a device special file or a link.
	if [[ -f "${_FILE}" ]]; then
		# Leave these two files as root.
		if [[ "moOde-CD-Rip-and-Play" != "${_FILE}" ]]; then
			if [[ "abcde-patched" != "${_FILE}" ]]; then
				echo "Changing owner of: ${_FILE}"

				chown "${RIPPED_MUSIC_OWNER}" "${_FILE}"

				_check_command_and_exit_if_error "${?}" 19 "Cannot change the owner of file: ${_FILE}"
			fi
		fi
	fi
done

_display_ok



##################################################################
# Remove our traps.
##################################################################

trap	-	EXIT ERR SIGHUP SIGINT SIGQUIT SIGABRT SIGTERM



##################################################################
# All done.
##################################################################

echo ""
echo -e "${Black}${On_Green}SUCCESS:${Colour_Off} CD ripper/player for ${HILITE}'moOde'${Colour_Off} updated ok."

exit 0
