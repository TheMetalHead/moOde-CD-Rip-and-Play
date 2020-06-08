#!/bin/bash
#
# A CD ripping/playing program for 'moOde'.
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
# Ensure the user is root. If not, restart it.
##################################################################

if [[ 0 != "$EUID" ]]; then
	# Restart the script as root.
	sudo "$0" "$@"

	exit "${?}"
fi

# We are root.



##################################################################
# Work out this files name, path and config pathname.
##################################################################

# Returns full path and name of this script.
# /home/pi/Src/cd-rip/cd-rip-and-or-play.sh
readonly	_FULLPATHNAME=$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null||echo "$0")

# The directory where this script resides.
# /home/pi/Src/cd-rip
readonly	_DIRECTORY=$(dirname "${_FULLPATHNAME}")

# Returns the script name with no paths or suffix.
# cd-rip-and-or-play
readonly	_SCRIPTNAME=$(basename "${BASH_SOURCE[0]}" .sh)

readonly	_LOCKNAME="/var/lock/${_SCRIPTNAME}.lock"

# The 'abcde.conf' file should be in the same directory as this cd ripping program.
# /home/pi/Src/cd-rip/abcde.conf
readonly	_ABCDE_CONFIG="${_DIRECTORY}/abcde.conf"

# /home/pi/Src/cd-rip/cd-rip-and-or-play.conf
readonly	_CDRIP_CONFIG="${_DIRECTORY}/${_SCRIPTNAME}.conf"

# /home/pi/Src/cd-rip/abcde
readonly	_CMD_ABCDE_PATCHED="${_DIRECTORY}/abcde-patched"

readonly	_SW_VERSION="1.1"



##################################################################
# Changes.
##################################################################

# Version 1.1	Sat 6-Jun-2020
#
#	Added code to only rip and tag one track when in debug mode and
#	also display the full text output of 'abcde'.
#
# Version 1.0	Fri 5-Jun-2020
#
#	Initial release.



##################################################################
# Import the cd-rip-and-play configuration file.
##################################################################

source	"${_CDRIP_CONFIG}" || { echo "ERROR: in configuration file '${_CDRIP_CONFIG}'"; exit 1; }

# This must come after 'source'.
PIPE="${TEMP_DIR}/${_SCRIPTNAME}.pipe"



##################################################################
# Only needed for test purposes.
##################################################################

# echo "Script name:       ${_SCRIPTNAME}"
# echo "Full pathname:     ${_FULLPATHNAME}"
# echo "Directory:         ${_DIRECTORY}"
# echo "Cdrip comfig:      ${_CDRIP_CONFIG}"
# echo "Abcde config:      ${_ABCDE_CONFIG}"
# echo "Cmd abcde patched: ${_CMD_ABCDE_PATCHED}"
# echo "Logfile:           ${LOGFILE}"



# exit 0



##################################################################
# 'exit' function replacement.
##################################################################

_exit_terminate() {
	_write_to_pipe "Done ${1}"

	${CMD_ECHO} "[EXIT]    All done. Exiting...(${1})" >> "${LOGFILE}"
	_log_log ""
	_log_log ""
	_log_log ""

	exit "${1}"
}



##################################################################
# Write to the pipe if it is open.
#
# Used to send the cd rip states to another process.
#
# Usage:	_write_to_pipe	Message_To_send
#
#	Messages
#	--------
#	"Begin"
#	"Ripping-start ${_G_TRACKS}"
#	"Ripping-done"
#	"Inserted-cd"
#	"Ejected-cd"
#	"Found ${_G_CD}"
#	"Mpd-play"
#	"Mpd-already-playing"
#	"Volume ${DEFAULT_VOLUME}"
#	"Artist ${_L_LINE}"
#	"Album ${_L_LINE}"
#	"Year ${_L_LINE}"
#	"Genre ${_L_LINE}"
#	"Track-added ${_L_LINE}"
#	"Track-failed ${_L_LINE}"
#	"Error ${_L_EXIT_CODE} - ${*}"
#	"Done ${1}"
#
##################################################################

_write_to_pipe() {
	# If there is a message to write.
	if [[ -n "${1}" ]]; then
		# If there is a pipe to write to.
		if [[ -p "${PIPE}" ]]; then
			${CMD_ECHO} "$1" > "${PIPE}"

			_log_debug "Pipe msg: ${1}"
		fi
	fi
}



##################################################################
# Logging functions.
##################################################################

_log_log() {
	if [ "${LOG_LEVEL_LOG}" -le "${_LOG_LEVEL}" ]; then
		${CMD_ECHO} "[LOG]     ${*}" >> "${LOGFILE}"
	fi
}



_log_ok() {
	if [ "${LOG_LEVEL_OK}" -le "${_LOG_LEVEL}" ]; then
		${CMD_ECHO} "[OK]      ${*}" >> "${LOGFILE}"
	fi
}



_log_warn() {
	if [ "${LOG_LEVEL_WARN}" -le "${_LOG_LEVEL}" ]; then
		${CMD_ECHO} "[WARN]    ${*}" >> "${LOGFILE}"
	fi
}



_log_error() {
	if [ "${LOG_LEVEL_ERROR}" -le "${_LOG_LEVEL}" ]; then
		${CMD_ECHO} "[ERROR]   ${*}" >> "${LOGFILE}"
	fi
}



_eject_cd() {
	${CMD_EJECT}

	_write_to_pipe "Ejected-cd"
}



# This always gets outputs to the log file and exits.
# It outputs the function name, line number and message.
#
# Usage:	_log_fatal_and_exit	Exit_Code	Message_To_Display
#
_log_fatal_and_exit() {
	local	_L_EXIT_CODE

	_L_EXIT_CODE="$1"

	shift

	# Displays the calling function name and the line number of the fatal test along with the exit code.
	${CMD_ECHO} "[FATAL]   ${FUNCNAME[1]} : Line ${BASH_LINENO[0]} : Exit ${_L_EXIT_CODE} - ${*}" >> "${LOGFILE}"

	_eject_cd

	_write_to_pipe "Error ${_L_EXIT_CODE} - ${*}"

	_exit_terminate "${_L_EXIT_CODE}"
}



# Tests for a non zero result code and outputs to the log file and exits.
# It outputs the function name, line number, message and command result code.
#
# Usage:	_log_if_fatal_and_exit	Last_Result_Code	Exit_Code	Message_To_Display
#
_log_if_fatal_and_exit() {
	local	_L_LAST_RESULT

	_L_LAST_RESULT="$1"

	if [[ "0" -ne "${LAST_RESULT}" ]]; then
		local	_L_EXIT_CODE="$2"

		shift
		shift

		# Displays the calling function name and the line number of the fatal test along with the exit code and the commands error code.
		${CMD_ECHO} "[FATAL]   ${FUNCNAME[1]} : Line ${BASH_LINENO[0]} : Exit ${_L_EXIT_CODE} - ${*} returned error code: ${_L_LAST_RESULT}" >> "${LOGFILE}"

		_eject_cd

		_write_to_pipe "Error ${_L_EXIT_CODE} - ${*}"

		_exit_terminate "${_L_EXIT_CODE}"
	fi
}



_log_debug() {
	if [ "${LOG_LEVEL_DEBUG}" -le "${_LOG_LEVEL}" ]; then
		${CMD_ECHO} "[DEBUG]   ${*}" >> "${LOGFILE}"
	fi
}



##################################################################
# Utility functions.
##################################################################

##################################################################
# Usage:	_log_result	"${RESULT}"
##################################################################

_log_result() {
	local	_L_FOUND

	_L_FOUND=0

	# Read the output from the command in row mode and insert each line into the array.
	# The || [[ -n $line ]] prevents the last line from being ignored if it doesn't end
	# with a \n (since read returns a non-zero exit code when it encounters EOF).
	# while IFS= read -r LINE || [[ -n "$LINE" ]]; do
	# -r -> Do not treat a backslash character in any special way. Consider each
	# backslash to be part of the input line.
	while IFS= read -r LINE || [[ -n "$LINE" ]]; do
#		# If the line is not empty.
		if [ -n "${LINE}" ]; then
			_log_debug "${LINE}"
			_L_FOUND=1
		fi		# End of 'if [ -n "${LINE}" ]; then'
	done <<< "${@}"

	if [ 0 -ne "${_L_FOUND}" ]; then
		_log_debug ""
	fi
}



##################################################################
# Usage:	_check_for_required_command	Exit_code	Required_command
##################################################################

_check_for_required_command() {
	local	_L_CMD

	# Cut off any command-line options that may have been added in.
	_L_CMD=$(echo "${2}" | cut -d' ' -f2)

	# The command must not be an empty string.
	if [ -z "${_L_CMD}" ]; then
		_log_fatal_and_exit "$1" "Required command '${_L_CMD}' not installed."
	fi

	# Check if the command exists and is executable.
	if [ ! -x "${_L_CMD}" ]; then
		_log_fatal_and_exit "$1" "Required command '${_L_CMD}' not installed."
	fi
}



##################################################################
# Usage:	_abort_on_trailing_slash	Exit_code	Variable_name
#
# Takes the name of a variable as an argument and checks its contents for a trailing slash.
##################################################################

_abort_on_trailing_slash() {
	local	_TMP
	local	_VAL

	_TMP="${2}"

	_VAL="${!_TMP}"

#	if [[ "/" == "${_VAL%"${VAL#?}"}" ]]; then

	if [[ "/" == "${_VAL: -1}" ]]; then
		_log_fatal_and_exit "${1}" "Cannot have a trailing slash: ${2} -> ${_VAL}"
	fi
}



##################################################################
# Usage:	_abort_on_leading_or_trailing_slash	Exit_code	Variable_name
#
# Takes the name of a variable as an argument and checks its contents for a trailing slash.
##################################################################

_abort_on_leading_or_trailing_slash() {
	local	_TMP
	local	_VAL

	_TMP="${2}"

	_VAL="${!_TMP}"

	_abort_on_trailing_slash "${1}" "${2}"

#	if [[ "/" == "${_VAL:0:1}" ]]; then

	if [[ "/" == "${_VAL%"${_VAL#?}"}" ]]; then
		_log_fatal_and_exit "${1}" "Cannot have a leading slash: ${2} -> ${_VAL}"
	fi
}



##################################################################
# Usage:	_abort_on_directory_not_found	Exit_code	Directory_to_check
##################################################################

_abort_on_directory_not_found() {
	if [[ ! -d "${2}" ]]; then
		_log_fatal_and_exit "${1}" "Cannot find directory: ${2}"
	fi
}



##################################################################
# Trim the leading and trailing spaces and remove any apostrophies ('), carriage returns and line feeds.
##################################################################

_sanitise_value() {
	local	_L_RV=$*

	_L_RV=${_L_RV//$'\''}
	_L_RV=${_L_RV//$'\r'}
	_L_RV=${_L_RV//$'\n'}

	${CMD_ECHO} "$_L_RV"
}



##################################################################
# Decode the artist and trackname line.
##################################################################

_decode_state_line_artist() {
	# If the line is not empty.
	if [ -n "${1}" ]; then
		while IFS=" " read -r artist ignore trackname; do
			_G_MPD_ARTIST=${artist}
			_G_MPD_TRACKNAME=${trackname}
		done <<< "${1}"

		_log_debug "Artist             -> ${_G_MPD_ARTIST}"
		_log_debug "Trackname          -> ${_G_MPD_TRACKNAME}"
	fi
}



##################################################################
# Decode the mpd state, current track index, number of tracks in the queue,
# current track time position, total track time and track position percentage.
##################################################################

_decode_state_line_state() {
	# If the line is not empty.
	if [ -n "${1}" ]; then
		while IFS=" " read -r state track time percent; do
			_G_MPD_STATE=${state}
			_G_MPD_TRAK=${track}
			_G_MPD_TIME=${time}
			_G_MPD_PERCENT=${percent}
		done <<< "${1}"

		# Strip the brackets [] from [paused].
		_G_MPD_STATE=${_G_MPD_STATE##*[}
		_G_MPD_STATE=${_G_MPD_STATE%]*}

		# Strip the # and / from #1/2.
		_G_MPD_TRAK=${_G_MPD_TRAK##*#}
		_G_MPD_QUEUE_INDEX=${_G_MPD_TRAK%/*}
		_G_MPD_QUEUE_COUNT=${_G_MPD_TRAK##*/}

		# Split the times from 1:54/3:34.
		_G_MPD_TRACK_TIME=${_G_MPD_TIME%/*}
		_G_MPD_TRACK_TIME_TOTAL=${_G_MPD_TIME##*/}

		# Strip the brackets () from (53%).
		_G_MPD_PERCENT=${_G_MPD_PERCENT##*(}
		_G_MPD_PERCENT=${_G_MPD_PERCENT%)*}

		_log_debug "State              -> ${_G_MPD_STATE}"
		_log_debug "Current track      -> ${_G_MPD_QUEUE_INDEX}"
		_log_debug "Queue count        -> ${_G_MPD_QUEUE_COUNT}"
		_log_debug "Current track time -> ${_G_MPD_TRACK_TIME}"
		_log_debug "Total track time   -> ${_G_MPD_TRACK_TIME_TOTAL}"
		_log_debug "Track position     -> ${_G_MPD_PERCENT}"
	fi
}



##################################################################
# Decode the volume, repeat mode, random mode, single mode and consume mode.
##################################################################

_decode_state_line_volume() {
	# If the line is not empty.
	if [ -n "${1}" ]; then
		while IFS=" " read -r _ignore _volume _ignore _repeat _ignore _random _ignore _single _ignore _consume; do
			_G_MPD_VOLUME=${_volume}
			_G_MPD_REPEAT=${_repeat}
			_G_MPD_RANDOM=${_random}
			_G_MPD_SINGLE=${_single}
			_G_MPD_CONSUME=${_consume}
		done <<< "${1}"

		_log_debug "Volume             -> ${_G_MPD_VOLUME}"
		_log_debug "Repeat             -> ${_G_MPD_REPEAT}"
		_log_debug "Random             -> ${_G_MPD_RANDOM}"
		_log_debug "Single             -> ${_G_MPD_SINGLE}"
		_log_debug "Consume            -> ${_G_MPD_CONSUME}"
	fi
}



##################################################################
# Decode the error line.
##################################################################

_decode_state_line_error() {
	# If the line is not empty.
	if [ -n "${1}" ]; then

# ERROR: Failed to decode /var/lib/mpd/music/My CDs/Metallica/Master Of Puppets/(Metallica) Master Of Puppets - 01) Battery.mp3;Failed to open '/var/lib/mpd/music/My CDs/Metallica/Master Of Puppets/(Metallica) Master Of Puppets - 01) Battery.mp3': No such file or directory

		while IFS=":;" read -r _L_ERROR _L_MSG1 _L_MSG2 _L_MSG3; do
			_log_debug "${_L_ERROR}"
			_log_debug "${_L_MSG1}"
			_log_debug "${_L_MSG2}"
			_log_debug "${_L_MSG3}"
		done <<< "${1}"
	fi
}



##################################################################
# Functions to deal with 'abcde' ripping.
##################################################################

_cleanup_abcde() {

###	# THIS DOES NOT WORK. WHY???
###	if [ -d "${TEMP_DIR}/abcde.*" ]; then


	for ABCDEDIR in "${TEMP_DIR}"/abcde.*
	do
		if [[ -d "${ABCDEDIR}" ]]; then
			_log_log "Removing temporary directory: '${ABCDEDIR}'"

			# Ignore any non-existent files, remove directories and their contents recursively, remove empty directories.
			${CMD_RM} -f -r -d "${ABCDEDIR}"
		fi
	done
}



_abcde_exit_error() {
	_log_debug "'abcde' returned error code: ${?}"

	_eject_cd

	_cleanup_abcde
}






##################################################################
##################################################################
##################################################################
##################################################################
##################################################################
##################################################################
#
# The start of the CD ripping/playing program for 'moOde'.
#
##################################################################
##################################################################
##################################################################
##################################################################
##################################################################
##################################################################



##################################################################
# Decide where to send the log output to.
##################################################################

# If in interactive mode. ie run from the command line.
if [[ -t 1 ]]; then
	LOGFILE="/dev/stdout"
else
	##################################################################
	# Create the log file if it does not exist.
	##################################################################

        # Create the cd rip log file if needed.
        LOGFILE="/var/log/${_SCRIPTNAME}.log"

	# If the log file does not exist.
	if [ ! -e "${LOGFILE}" ]; then
		${CMD_TOUCH} "${LOGFILE}"
	fi

	# If the log file exists and is not writable.
	if [ ! -w "${LOGFILE}" ]; then
		${CMD_CHMOD} 644 "${LOGFILE}"
	fi

	# If the log file exists and is still not writable then disable output.
	if [ ! -w "${LOGFILE}" ]; then
		LOGFILE="/dev/null"

                _LOG_LEVEL=${LOG_LEVEL_NOLOG}
	fi
fi

##################################################################
# Output the software version.
##################################################################

_log_log "Version ${_SW_VERSION}"

##################################################################
# Set up the pipe if available.
# This is used by '_write_to_pipe()'.
##################################################################

if [[ ! -p "${PIPE}" ]]; then
	_log_warn "Pipe reader not running."

	PIPE=""
else
	_log_debug "Found pipe: ${PIPE}"
fi

##################################################################
# Read '/etc/mpd.conf' and look at what 'music_directory' points to.
##################################################################

_G_MPD_MUSIC_DIR=""

_log_debug "Looking in '/etc/mpd.conf' for the music directory."

# Read the file in row mode and extract each line.
while IFS= read -r _L_LINE; do
	# music_directory	"/var/lib/mpd/music"
	_L_KEY=${_L_LINE% *}
	_L_VALUE=${_L_LINE##* }

	if [ "${_L_KEY}" == "music_directory" ]; then
		# Remove the " character from the start and end of the value token.
		_L_VALUE=${_L_VALUE#\"}
		_L_VALUE=${_L_VALUE%\"}

		# Returns: /var/lib/mpd/music
		_G_MPD_MUSIC_DIR="${_L_VALUE}"

		break
	fi
done < "/etc/mpd.conf"

if [[ -z "${_G_MPD_MUSIC_DIR}" ]]; then
	_log_fatal_and_exit 2 "Cannot find 'music_directory' entry in '/etc/mpd.conf'"
fi

# If the directory does not exist.
if [[ ! -d "${_G_MPD_MUSIC_DIR}" ]]; then
	_log_fatal_and_exit 3 "Cannot find directory: ${_G_MPD_MUSIC_DIR}"
fi

# Got: /var/lib/mpd/music
_log_debug "Got: ${_G_MPD_MUSIC_DIR}"



##################################################################
# Validate some of the variables.
##################################################################

# No trailing slash.
_abort_on_trailing_slash 4 _G_MPD_MUSIC_DIR
_abort_on_trailing_slash 5 TEMP_DIR

# No leading or trailing slashes.
_abort_on_leading_or_trailing_slash 6 LIBRARY_TAG
_abort_on_leading_or_trailing_slash 7 MUSIC_MNT_SOURCE
_abort_on_leading_or_trailing_slash 8 DEFAULT_SAVED_USER_PLAYLIST
_abort_on_leading_or_trailing_slash 9 DEFAULT_SAVED_USER_PLAYLIST_EXTENSION



# The music sub directory must be empty or have no leading or trailing slashes.
if [ -z "${MUSIC_SUB_DIR}" ]; then
	# This is passed to 'abcde'.
	# '/var/lib/mpd/music/My CDs' or '/var/lib/mpd/music/SDCARD' or '/var/lib/mpd/music/USB'.
	readonly	MUSIC_DIR="${_G_MPD_MUSIC_DIR}/${LIBRARY_TAG}"
else
	# Not empty.
	_abort_on_leading_or_trailing_slash 10 MUSIC_SUB_DIR

	# This is passed to 'abcde'.
	# '/var/lib/mpd/music/My CDs/${MUSIC_SUB_DIR}' or '/vsr/lib/mpd/music/SDCARD/${MUSIC_SUB_DIR}' or '/var/lib/mpd/music/USB/${MUSIC_SUB_DIR}'.
	readonly	MUSIC_DIR="${_G_MPD_MUSIC_DIR}/${LIBRARY_TAG}/${MUSIC_SUB_DIR}"
fi



##################################################################
# We cannot use mpd to check if we have ripped the cd because we
# do not yet know the artist and album names without looking up
# the cd on the likes of Musicbrainz. This would introduce a long
# delay as well as accessing Musicbrainz twice if we need to rip
# the cd. Therefore we use simple database using files that can
# also be viewed from the command line.
##################################################################


# Must not have a trailing slash.
# /var/lib/mpd/music/My CDs/.Music CDs Ripped
_G_DISCID_DIR="${MUSIC_DIR}/.Music CDs Ripped"

# If the disc id directory does not exist, create it.
if [ ! -d "${_G_DISCID_DIR}" ]; then
	_log_log "Creating '${_G_DISCID_DIR}' directory."

	{ ${CMD_MKDIR} "${_G_DISCID_DIR}" >> "${LOGFILE}"; } 2>&1

	_log_if_fatal_and_exit "${?}" 11 "Cannot create: ${_G_DISCID_DIR}. 'mkdir'"

	{ ${CMD_CHOWN} "${RIPPED_MUSIC_OWNER}" "${_G_DISCID_DIR}" >> "${LOGFILE}"; } 2>&1

	_log_if_fatal_and_exit "${?}" 12 "Cannot change the owner of '${_G_DISCID_DIR}' to '${RIPPED_MUSIC_OWNER}'. 'chown'"
fi

# CDs ripped dir: /var/lib/mpd/music/My CDs/.Music CDs Ripped
_log_debug "CDs ripped dir: ${_G_DISCID_DIR}"

# Mpd music dir:  /var/lib/mpd/music
_log_debug "Mpd music dir:  ${_G_MPD_MUSIC_DIR}"

# Mount dir:      /mnt/CD
_log_debug "Mount dir:      /mnt/${MUSIC_MNT_SOURCE}"

#  Music sub dir:
_log_debug "Music sub dir:  ${MUSIC_SUB_DIR}"

# Music dir:      /var/lib/mpd/music/My CDs
_log_debug "Music dir:      ${MUSIC_DIR}"

# Temp dir:       /run
_log_debug "Temp dir:       ${TEMP_DIR}"

# /var/lib/mpd/music
_abort_on_directory_not_found 13 "${_G_MPD_MUSIC_DIR}"

# /run
_abort_on_directory_not_found 14 "${TEMP_DIR}"

# /var/lib/mpd/music/My CDs
_abort_on_directory_not_found 15 "${MUSIC_DIR}"

_log_debug "Directories are valid."

##################################################################
# Check for the existance of the 'abcde' config file.
##################################################################

# If the config file does not exist or is empty.
if [[ ! -s "${_ABCDE_CONFIG}" ]]; then
	_log_fatal_and_exit 16 "Cannot find configuration file: ${_ABCDE_CONFIG}"
fi

# Using config file: /home/pi/Src/cd-rip/abcde.conf
_log_debug "Using config file: ${_ABCDE_CONFIG}"

##################################################################
# Check for the required commands.
# Exit if command not found.
##################################################################

for CMD_TO_CHECK in ${CMD_CDDISCID} ${CMD_ABCDE} ${CMD_EJECT} ${CMD_FLOCK} ${CMD_MPC}
do
	_check_for_required_command 17 "${CMD_TO_CHECK}"
done

_log_debug "Required commands are installed."

##################################################################
# Work out the CDROM path.
##################################################################

${CMD_SLEEP} 0.5

# Find out which device the CDROM appears as. Must have no trailng slash.
CDROM="/dev/cdrom"

# If the cdrom does not exist.
if [ ! -e "${CDROM}" ]; then
	# If not found.
	CDROM=""
	CDPATH="/dev/sr"

	if [ -e "${CDPATH}0" ]; then
		CDROM="${CDPATH}0"
	fi

	if [ -e "${CDPATH}1" ]; then
		CDROM="${CDPATH}1"
	fi
fi

#${CMD_CHMOD} 644 ${CDROM}

# If the line is empty. ie the cdrom path is not found.
if [ -z "${CDROM}" ]; then
	_log_fatal_and_exit 18 "Cannot find the CDROM drive."
fi

# Using CDROM drive: /dev/cdrom
_log_debug "Using CDROM drive: ${CDROM}"

##################################################################
#
##################################################################

# Set the speed and close the tray.
${CMD_EJECT} -x 8 ${CDROM}

_write_to_pipe "Inserted-cd"



# Get the disk id.
_G_CD_ID=$(${CMD_CDDISCID} ${CDROM})

# ab0ead0c 12 182 25045 49402 66475 95507 125822 143847 162175 191332 210572 233712 264437 3759

_log_if_fatal_and_exit "${?}" 19 "Cannot get the cd disc id. 'cd-discid'"

# [cd_id] 520cd708 8 183 23625 62268 91980 121008 158255 183755 221803 3289
_log_debug "[cd_id] ${_G_CD_ID}"

_G_DISC_ID=$(${CMD_ECHO} "${_G_CD_ID}" | cut -d' ' -f1)
_G_TRACKS=$(${CMD_ECHO} "${_G_CD_ID}" | cut -d' ' -f2)

# [disc_id] 520cd708
_log_debug "[disc_id] ${_G_DISC_ID}"

# [tracks] 8
_log_debug "[tracks] ${_G_TRACKS}"

_G_DISC_ID=$( _sanitise_value "${_G_DISC_ID}" )

_write_to_pipe "Begin"

##################################################################
#
##################################################################

# Check to see if we have ripped the CD.

# /var/lib/mpd/music/My CDs/.Music CDs Ripped/520cd708
_G_CD_DISC_ID="${_G_DISCID_DIR}/${_G_DISC_ID}"

# Looking for: /var/lib/mpd/music/My CDs/.Music CDs Ripped/520cd708 -*
_log_debug "Looking for: ${_G_CD_DISC_ID} -*"

# If the tag exists. Returns 0 if found else 2 if not found.
${CMD_LS} "${_G_CD_DISC_ID}"\ -*._* 2>&1

RV=${?}

_log_debug "Log level ${_LOG_LEVEL}"
_log_debug "${CDROM}"
_log_debug "${MUSIC_DIR}                      # /var/lib/mpd/music/SDCARD/CD or /var/lib/mpd/music/My CDs"
_log_debug "${MUSIC_SUB_DIR}                                               # CD"
_log_debug "${_G_DISCID_DIR}    # /var/lib/mpd/music/My CDs/.Music CDs Ripped"
_log_debug "${_LOCKNAME}                                # /var/lock/${_SCRIPTNAME}.lock"
_log_debug "${TEMP_DIR}                                           # /run"
_log_debug "${LOGFILE}                # /var/log/${_SCRIPTNAME}.log"

# FOR DEBUG...
#_eject_cd
#exit 0



# If the tag does not exist. ie the CD has not been ripped.
if [ 0 -ne "${RV}" ]; then
	# The disc id has not been found indicating that the CD has not been previously ripped.

	# Cannot find: /var/lib/mpd/music/My CDs/.Music CDs Ripped/520cd708 -*
	_log_log "Cannot find: ${_G_CD_DISC_ID} -*"
	_log_log ""
	_log_log "Ripping ${_G_TRACKS} CD tracks. Start time: $(date)"
	_log_log ""

	_write_to_pipe "Ripping-start ${_G_TRACKS}"

	_G_START_TIME=$(date +%s)

	##################################################################
	# This deals with the CD ripping.
	##################################################################

	(

		# Wait for lock on "/var/lock/${_SCRIPTNAME}.lock" (fd 200) for two hours.

		# -x  - Obtain an exclusive lock, sometimes called a write lock.
		# -w  - Fail if the lock cannot be acquired within seconds.
		# 200 - Uses an open file by its file descriptor number.
		${CMD_FLOCK} -x -w 7200 200 || _log_fatal_and_exit 20 "Ripping failed. Cannot aquire the lock."

		# Ensure that 'abcde' does not fail if it finds a previous unfinished rip.
		_cleanup_abcde

		# export	-f	_write_to_pipe
		export	-f	_log_log
		export	-f	_log_warn
		export	-f	_log_debug

		# Allow 'abcde' acess to these variables.
		# Export needed things so they can be read in this subshell.

		export	LOG_LEVEL_NOLOG
		export	LOG_LEVEL_FATAL
		export	LOG_LEVEL_ERROR
		export	LOG_LEVEL_WARN
		export	LOG_LEVEL_OK
		export	LOG_LEVEL_LOG
		export	LOG_LEVEL_DEBUG

		export	_LOG_LEVEL
		export	CDROM
		export	RIPPED_MUSIC_OWNER	# 'pi:pi'
		export	MUSIC_DIR		# '/var/lib/mpd/music/My CDs' or '/var/lib/mpd/music/USB/CD'.
		export	MUSIC_SUB_DIR		# '' or 'CD'
		export	_G_DISCID_DIR		# '/var/lib/mpd/music/My CDs/.Music CDs Ripped'
		export	TEMP_DIR		# '/run'
		export	LOGFILE			# '/var/log/${_SCRIPTNAME}.log'

		# Enable our traps for 'abcde'.
		#
		# Number	SIG		Meaning
		# 0		0		On exit from shell
		# 1		SIGHUP		Clean tidyup
		# 2		SIGINT		Interrupt (CTRL-C)
		# 3		SIGQUIT		Quit
		# 6		SIGABRT		Cancel
		# 9		SIGKILL		Die Now (cannot be trap'ped)
		# 15		SIGTERM		Terminate
		#
		# If a signal is EXIT (0) the command arg is executed on exit from the shell.
		# If a signal is ERR, the command arg is executed whenever a the command has a non-zero exit status.
		# If a signal is RETURN, the command arg is executed each time a shell function
		# or a script executed with the . or source builtins finishes executing.
		trap	_abcde_exit_error	EXIT ERR SIGHUP SIGINT SIGQUIT SIGABRT SIGTERM


#		# Info from somewhere on the web.
#
#		# ABCDE has a bug where it tries to rip data cd's. But the version that fixes it itself has
#		# even more. So instead of trying to install the new version, which doesn't work, we use a command
#		# similar to the one ABCDE uses to determine the number of valid tracks (since it assumes the data
#		# track always occurs at the end, which in some game CD's it doesn't) and pass it to the command
#		# line. Yes, it really is one line.
#		local VALIDTRACKS="$(cdparanoia -d $CDROM -Q 2>&1 | egrep '^[[:space:]]+[[:digit:]]' | awk '{print $1}' | tr -d "." | tr '\n' ' ')"
#
##		logger -p $LOGDEST.info "Info ($PROCESS): Starting encoding."
#
#		abcde $VALIDTRACKS > /dev/null 2>&1



		# Uses a specific config file.

		# TEST: Do the ripping.
		# Use Unix PIPES to read and encode in one step.
		# Duration: 3:40
		# { ${_CMD_ABCDE_PATCHED} -c "${_ABCDE_CONFIG}" -P 2-3 >> "${LOGFILE}"; } 2>&1

		# TEST: Normal read and encode.
		# Duration: 3:10
		# { ${_CMD_ABCDE_PATCHED} -c "${_ABCDE_CONFIG}" 2-3 >> "${LOGFILE}"; } 2>&1



#		# TEST: Use the original 'abcde'.
#		{ ${CMD_ABCDE} -c "${_ABCDE_CONFIG}" 2 >> "${LOGFILE}"; } 2>&1

#		# TEST: Use the patched 'abcde-patched'.
#		{ ${_CMD_ABCDE_PATCHED} -c "${_ABCDE_CONFIG}" 2 >> "${LOGFILE}"; } 2>&1



		# Any error from the 'abcde' ripping software will result in an immediate
		# call to '_abcde_exit_error' here. This will eject the cd and clean up
		# the 'abcde' temporary directory.
		if [ "${LOG_LEVEL_DEBUG}" -eq "${_LOG_LEVEL}" ]; then
			# We only rip and tag one track when in debug mode
			# and also display the full text output of 'abcde'.
			# Run 2 encoder jobs while it rips: -j 2 Is this the same as MAXPROCS=2 ?
			_G_RESULT=$( { ${_CMD_ABCDE_PATCHED} -c "${_ABCDE_CONFIG}" 1 >> "${LOGFILE}"; } 2>&1 )

			RV=$?

			_log_result "${_G_RESULT}"
		else
			{ ${_CMD_ABCDE_PATCHED} -c "${_ABCDE_CONFIG}" >> "${LOGFILE}"; } 2>&1

			RV=$?
		fi



		# Remove all our traps.
		trap	-	EXIT ERR SIGHUP SIGINT SIGQUIT SIGABRT SIGTERM

		# Remove the exports.
		# export	-n	_write_to_pipe

		export	-n	_log_log
		export	-n	_log_warn
		export	-n	_log_debug

		export	-n	LOG_LEVEL_NOLOG
		export	-n	LOG_LEVEL_FATAL
		export	-n	LOG_LEVEL_ERROR
		export	-n	LOG_LEVEL_WARN
		export	-n	LOG_LEVEL_OK
		export	-n	LOG_LEVEL_LOG
		export	-n	LOG_LEVEL_DEBUG

		export	-n	_LOG_LEVEL
		export	-n	CDROM
		export	-n	RIPPED_MUSIC_OWNER
		export	-n	MUSIC_DIR
		export	-n	MUSIC_SUB_DIR
		export	-n	_G_DISCID_DIR
		export	-n	TEMP_DIR
		export	-n	LOGFILE

		_log_if_fatal_and_exit "${RV}" 21 "Ripping failed. 'abcde'"

	) 200>"${_LOCKNAME}"

	# We always come here whenever there is an ripping error or success because of the flock command.
	RV=${?}

	# If we have a fatal exit code from above.
	if [ "0" -ne "${RV}" ]; then
		_exit_terminate "${RV}"
	fi



	${CMD_TRUNCATE} "${MOODE_LIB_CACHE_FILE}" --size 0 > /dev/null

	RV=$?

	if [[ 0 != "${RV}" ]] ; then
		_log_warn "Cannot truncate '${MOODE_LIB_CACHE_FILE}'"
	fi

	_eject_cd

	_log_log ""
	_log_log "CD ripped ok. End time: $(date)"
	_log_log "Total time elapsed: $(date -ud "@$(($(date +%s) - _G_START_TIME))" +%-M:%S) (MM:SS)"
	_log_log ""

	_G_RESULT=$(${CMD_MPC} update 2>&1)

	_log_result "${_G_RESULT}"

	_write_to_pipe "Ripping-done"
fi	# End of 'if [ 0 -ne "${RV}" ]; then'



##################################################################
# If the disc id file exists indicating it has been ripped,
# add its list of mp3 files to 'moOde's playlist queue.
##################################################################

# Looking for '/var/lib/mpd/music/My CDs/.Music CDs Ripped/520cd708 -*' again.
_log_ok "Looking for '${_G_CD_DISC_ID} -*' again."

# Look for the best bitrate.
for _MODE in "flac" "mpc" "mp3"; do
	# Returns 0 if found else 2 if not found.
	_G_CD=$(${CMD_LS} "${_G_CD_DISC_ID}"\ -*._"${_MODE}" 2>&1)

	RV=${?}

	if [ 0 -eq "${RV}" ]; then
		break
	fi
done

# If the result of the '${CMD_LS} "${_G_CD_DISC_ID}"-* is not zero.
if [ 0 -ne "${RV}" ]; then
	_log_error "Cannot find '${_G_CD_DISC_ID} -*'"
else
	##################################################################
	# Read the current mpd status.
	#
	# The return values from mpc status can be any of the following:
	#
	#	Metallica - Battery
	#	[paused]  #1/2   1:54/3:34 (53%)
	#	[playing] #1/2   0:44/3:34 (20%)
	#	volume: 10%   repeat: off   random: off   single: off   consume: off
	#	ERROR: Failed to decode /var/lib/mpd/music/My CDs/Metallica/Master Of Puppets/(Metallica) Master Of Puppets - 01) Battery.mp3;Failed to open '/var/lib/mpd/music/My CDs/Metallica/Master Of Puppets/(Metallica) Master Of Puppets - 01) Battery.mp3': No such file or directory
	##################################################################

	_G_MPD_ARTIST=""
	_G_MPD_TRACKNAME=""

	_G_MPD_STATE=""
	_G_MPD_QUEUE_INDEX=""
	_G_MPD_QUEUE_COUNT=""
	_G_MPD_TRACK_TIME=""
	_G_MPD_TRACK_TIME_TOTAL=""
	_G_MPD_PERCENT=""

	_G_MPD_VOLUME=""
	_G_MPD_REPEAT=""
	_G_MPD_RANDOM=""
	_G_MPD_SINGLE=""
	_G_MPD_CONSUME=""



	_log_debug "Getting the mpd state:"

	# Read the output from the command in row mode and insert each line into the array.
	# The || [[ -n "$_L_LINE" ]] prevents the last line from being ignored if it doesn't end
	# with a \n (since read returns a non-zero exit code when it encounters EOF).
	# while IFS= read -r _L_LINE || [[ -n "$_L_LINE" ]]; do
	# -r -> Do not treat a backslash character in any special way. Consider each
	# backslash to be part of the input line.
	while IFS= read -r _L_LINE || [[ -n "${_L_LINE}" ]]; do
		FIRST=${_L_LINE%% *}		# Extract first word from line

##		_log_debug "Got: ${_L_LINE}"
##		_log_debug "First: ${FIRST}"

		# If starts with '[' and ends with ']'.
#		if [[ ( "${FIRST}" == [* ) && ( "${FIRST}" == *] ) ]]; then
		if [[ ( "${FIRST}" == "[*" ) && ( "${FIRST}" == "*]" ) ]]; then
			_decode_state_line_state "${_L_LINE}"
		else
			# If starts with 'volume:'.
			if [[ "${FIRST}" == "volume:" ]]; then
				_decode_state_line_volume "${_L_LINE}"
			else
				# If starts with 'ERROR:'.
				if [[ "${FIRST}" == "ERROR:" ]]; then
					_decode_state_line_error "${_L_LINE}"
				else
					# Must be artist line.
					_decode_state_line_artist "${_L_LINE}"
				fi
			fi
		fi
	done < <(${CMD_MPC} status)



	##################################################################
	# These are the available tokens.
	#
	#	_G_MPD_ARTIST		-> Artist
	#	_G_MPD_TRACKNAME	-> Track name
	#
	#	_G_MPD_STATE		-> Current mpd state
	#	_G_MPD_QUEUE_INDEX	-> Current track
	#	_G_MPD_QUEUE_COUNT	-> Queue count
	#	_G_MPD_TRACK_TIME	-> Current track position time
	#	_G_MPD_TRACK_TIME_TOTAL	-> Total track time
	#	_G_MPD_PERCENT		-> Track position percentage
	#
	#	_G_MPD_VOLUME		-> Current volume level
	#	_G_MPD_REPEAT		-> Repeat mode
	#	_G_MPD_RANDOM		-> Random mode
	#	_G_MPD_SINGLE		-> Single mode
	#	_G_MPD_CONSUME		-> Consume mode
	##################################################################



	##################################################################
	# Decide if we need to reduce the volume to zero and save
	# the current users playlist and clear it from the mpd queue.
	##################################################################

	# If we have not got the state line or we are not playing any tracks.
	if [[ "playing" != "${_G_MPD_STATE}" ]]; then
		# Saving the playlist as: Saved-User-Playlist
		_log_log "Saving the playlist as: ${DEFAULT_SAVED_USER_PLAYLIST}"

		# Set the volume to 0.
		{ ${CMD_ROTVOL} -dn 234 2>&1; } > /dev/null

		_G_MPD_VOLUME="0%"

		# Delete the old saved mpd queue if it exists.
		{ ${CMD_MPC} -q rm "${DEFAULT_SAVED_USER_PLAYLIST}" 2>&1; } > /dev/null

		# Save the current list of tracks in the mpd queue.
		{ ${CMD_MPC} -q save "${DEFAULT_SAVED_USER_PLAYLIST}" 2>&1; } > /dev/null

		RV=${?}

		if [ 0 -ne "${RV}" ]; then
			_log_error "Cannot save: '${DEFAULT_SAVED_USER_PLAYLIST}${DEFAULT_SAVED_USER_PLAYLIST_EXTENSION}'. Return code: ${RV}"
		fi

		# Clear the list of tracks from the mpd queue.
		{ ${CMD_MPC} -q clear 2>&1; } > /dev/null

		RV=${?}

		if [ 0 -ne "${RV}" ]; then
			_log_error "Cannot clear the list of tracks from the mpd queue'. Return code: ${RV}"
		fi
	fi

	# Found: /var/lib/mpd/music/My CDs/.Music CDs Ripped/520cd708 - Metallica - Master Of Puppets
	_log_log "Found: ${_G_CD}"

	_write_to_pipe "Found ${_G_CD}"

	# This is only needed for the HiFi software.
	${CMD_SLEEP} 2.5

	##################################################################
	#
	##################################################################

	# To preserve white space at the beginning or the end of a line, specify IFS= (with no value)
	# immediately before the read command. After reading is completed, the IFS returns to its previous value.
	#
	# -r = Use "raw input". Causes read to interpret backslashes literally, rather than interpreting them as escape characters.
	_G_ADDED=0
	_G_FOUND_MARKER=0
	_G_LINE_COUNT=0

	while IFS= read -r _L_LINE; do
		# Do something with ${_L_LINE}.

		# Metallica
		# Master Of Puppets
		# 1986
		# Metal
		# ############################################################
		#
		# Metallica/Master Of Puppets/(Metallica) Master Of Puppets - 01) Battery.mp3

		_G_LINE_COUNT=$((1 + _G_LINE_COUNT))

#		_log_debug "Got line ${_G_LINE_COUNT}: ${_L_LINE}"

		# If the line is not empty.
		if [ -n "${_L_LINE}" ]; then
			if [ 0 -eq ${_G_FOUND_MARKER} ]; then
				#		    123456789012345678901234567890
				if [[ "${_L_LINE}" == "##############################"* ]]; then
					# Found marker on line 5
					_log_debug "Found marker on line ${_G_LINE_COUNT}"

					_eject_cd	### WHY WHY WHY cos abcde should have ejected the cd

					_G_FOUND_MARKER=1
				else
					case ${_G_LINE_COUNT} in
						1)	# Optional artist.
							# Got artist: Metallica
							_log_debug "Got artist: ${_L_LINE}"
							_write_to_pipe "Artist ${_L_LINE}"

						;;
						2)	# Optional album.
							# Got album: Master Of Puppets
							_log_debug "Got album: ${_L_LINE}"
							_write_to_pipe "Album ${_L_LINE}"
						;;
						3)	# Optional year.
							# Got year: 1986
							_log_debug "Got year: ${_L_LINE}"
							_write_to_pipe "Year ${_L_LINE}"
						;;
						4)	# Optional genre.
							# Got genre: Metal
							_log_debug "Got genre: ${_L_LINE}"
							_write_to_pipe "Genre ${_L_LINE}"
						;;
						*)	# Ignore this line.
							_log_debug "Ignoring: ${_L_LINE}"
						;;
					esac
				fi
			else
				# Found a track to add.

				# file:///Music/Files/Scorpions - The Zoo.mp3
				# Metallica/Master Of Puppets/(Metallica) Master Of Puppets - 01) Battery.mp3

				# Adding track: Metallica/Master Of Puppets/(Metallica) Master Of Puppets - 01) Battery.mp3
				_log_debug "Adding track: ${_L_LINE}"

				if [ -z "${MUSIC_SUB_DIR}" ]; then
#					MSG=$(${CMD_MPC} -v add "${MUSIC_MNT_SOURCE}/${_L_LINE}")
					MSG=$(${CMD_MPC} -v add "${LIBRARY_TAG}/${_L_LINE}")
				else
#					MSG=$(${CMD_MPC} -v add "${MUSIC_MNT_SOURCE}/${MUSIC_SUB_DIR}/${_L_LINE}")
					MSG=$(${CMD_MPC} -v add "${LIBRARY_TAG}/${MUSIC_SUB_DIR}/${_L_LINE}")
				fi

				RV=$?

				if [ 0 -eq "${RV}" ]; then
					_G_ADDED=1

					# adding: My CDs/Metallica/Master Of Puppets/(Metallica) Master Of Puppets - 01) Battery.mp3
					_log_ok "${MSG}"
					_write_to_pipe "Track-added ${_L_LINE}"

				else
					_log_error "Return code ${RV}. ${MSG}"
					_write_to_pipe "Track-failed ${_L_LINE}"
				fi
			fi	# End of 'if [ 0 -eq ${_G_FOUND_MARKER} ]; then'
		fi		# End of 'if [ -n "${_L_LINE}" ]; then'
	done < "$_G_CD"		# Read the saved disc id audio file list

	##################################################################
	# Decide if we need to change the volume or restore the playlist.
	##################################################################

	# Mpd state:
	_log_debug "Mpd state: ${_G_MPD_STATE}"

	# If already playing a track there is no need to start playing and leave the volume alone.
	if [ "playing" == "${_G_MPD_STATE}" ]; then
		_log_debug "We are already playing a track. Do not change the volume."

		_write_to_pipe "Mpd-already-playing"
	else
		# We are not playing a track.

		_log_debug "We are not playing a track."

		# If added some tracks.
		if [ 0 -ne ${_G_ADDED} ]; then
			_log_debug "Current volume is: ${_G_MPD_VOLUME}"

			# If the volume is at 0 change it, otherwise leave it alone.
			if [ "0%" = "${_G_MPD_VOLUME}" ]; then
				_log_debug "Tracks have been added. Changing the volume from 0 to ${DEFAULT_VOLUME}"

				{ ${CMD_ROTVOL} -up "${DEFAULT_VOLUME}" > /dev/null; } 2>&1
				_write_to_pipe "Volume ${DEFAULT_VOLUME}"
			fi

			# Start playing from track 1.
			RESULT=$(${CMD_MPC} play 2>&1)

			# We are not playing a track.
			# Current volume is: 0%
			# Tracks have been added. Changing the volume from 0 to 10
			# Metallica - Battery
			# [playing] #1/8   0:00/8:35 (0%)
			# volume: 10%   repeat: off   random: off   single: off   consume: off
			_log_result "${RESULT}"
			_write_to_pipe "Mpd-play"
		else
			_log_log "No tracks have been found to add to the playlist."
			_log_log "Reloading the previous playlist."

			# If no tracks added then reload the saved users playlist.
			{ ${CMD_MPC} -q load "${DEFAULT_SAVED_USER_PLAYLIST}" > /dev/null; } 2>&1

			RV=${?}

			if [ 0 -ne "${RV}" ]; then
				_log_warn "Cannot load: '${DEFAULT_SAVED_USER_PLAYLIST}${DEFAULT_SAVED_USER_PLAYLIST_EXTENSION}'. Return code: ${RV}"
			else
				# Delete the saved playlist.
				{ ${CMD_MPC} -q rm "${DEFAULT_SAVED_USER_PLAYLIST}" > /dev/null; } 2>&1

				RV=${?}

				if [ 0 -ne "${RV}" ]; then
					_log_warn "Cannot delete: '${DEFAULT_SAVED_USER_PLAYLIST}${DEFAULT_SAVED_USER_PLAYLIST_EXTENSION}'. Return code: ${RV}"
				fi
			fi
		fi	# End of 'if [ 0 -ne ${_G_ADDED} ]; then'
	fi		# End of 'if [ "playing" == "${_G_MPD_STATE}" ]; then'
fi			# End of 'if [ 0 -ne "${RV}" ]; then'

##################################################################
# Yay! We have success.
##################################################################

# All done. Exiting...(0)
_exit_terminate 0
