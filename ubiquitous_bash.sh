#!/usr/bin/env bash

#Universal debugging filesystem.
_user_log-ub() {
	# DANGER Do NOT create automatically, or reference any existing directory!
	! [[ -d "$HOME"/.ubcore/userlog ]] && cat - > /dev/null 2>&1 && return 0
	
	#Terminal session may be used - the sessionid may be set through .bashrc/.ubcorerc .
	if [[ "$sessionid" != "" ]]
	then
		cat - >> "$HOME"/.ubcore/userlog/u-"$sessionid".log
		return 0
	fi
	cat - >> "$HOME"/.ubcore/userlog/u-undef.log
	
	return 0
}

#Cyan. Harmless status messages.
_messagePlain_nominal() {
	echo -e -n '\E[0;36m '
	echo -n "$@"
	echo -e -n ' \E[0m'
	echo
	return 0
}

#Blue. Diagnostic instrumentation.
_messagePlain_probe() {
	echo -e -n '\E[0;34m '
	echo -n "$@"
	echo -e -n ' \E[0m'
	echo
	return 0
}

#Blue. Diagnostic instrumentation.
_messagePlain_probe_expr() {
	echo -e -n '\E[0;34m '
	echo -e -n "$@"
	echo -e -n ' \E[0m'
	echo
	return 0
}

#Green. Working as expected.
_messagePlain_good() {
	echo -e -n '\E[0;32m '
	echo -n "$@"
	echo -e -n ' \E[0m'
	echo
	return 0
}

#Yellow. May or may not be a problem.
_messagePlain_warn() {
	echo -e -n '\E[1;33m '
	echo -n "$@"
	echo -e -n ' \E[0m'
	echo
	return 0
}

#Red. Will result in missing functionality, reduced performance, etc, but not necessarily program failure overall.
_messagePlain_bad() {
	echo -e -n '\E[0;31m '
	echo -n "$@"
	echo -e -n ' \E[0m'
	echo
	return 0
}

##Parameters
#"--shell", ""
#"--profile"
#"--parent", "--embed", "--return", "--devenv"
#"--call", "--script" "--bypass"

ub_import=
ub_import_param=
ub_import_script=
ub_loginshell=

[[ "${BASH_SOURCE[0]}" != "${0}" ]] && ub_import="true"
([[ "$1" == '--profile' ]] || [[ "$1" == '--script' ]] || [[ "$1" == '--call' ]] || [[ "$1" == '--return' ]] || [[ "$1" == '--devenv' ]] || [[ "$1" == '--shell' ]] || [[ "$1" == '--bypass' ]] || [[ "$1" == '--parent' ]] || [[ "$1" == '--embed' ]]) && ub_import_param="$1" && shift
([[ "$0" == "/bin/bash" ]] || [[ "$0" == "-bash" ]] || [[ "$0" == "/usr/bin/bash" ]] || [[ "$0" == "bash" ]]) && ub_loginshell="true"	#Importing ubiquitous bash into a login shell with "~/.bashrc" is the only known cause for "_getScriptAbsoluteLocation" to return a result such as "/bin/bash".
[[ "$ub_import" == "true" ]] && ! [[ "$ub_loginshell" == "true" ]] && ub_import_script="true"

_messagePlain_probe_expr '$0= '"$0"'\n ''$1= '"$1"'\n ''ub_import= '"$ub_import"'\n ''ub_import_param= '"$ub_import_param"'\n ''ub_import_script= '"$ub_import_script"'\n ''ub_loginshell= '"$ub_loginshell" | _user_log-ub

# DANGER Prohibited import from login shell. Use _setupUbiquitous, call from another script, or manually set importScriptLocation.
# WARNING Import from shell can be detected. Import from script cannot. Asserting that script has been imported is possible. Asserting that script has not been imported is not possible. Users may be protected from interactive mistakes. Script developers are NOT protected.
if [[ "$ub_import_param" == "--profile" ]]
then
	if ([[ "$profileScriptLocation" == "" ]] ||  [[ "$profileScriptFolder" == "" ]]) && _messagePlain_bad 'import: profile: missing: profileScriptLocation, missing: profileScriptFolder' | _user_log-ub
	then
		return 1 >/dev/null 2>&1
		exit 1
	fi
elif ([[ "$ub_import_param" == "--parent" ]] || [[ "$ub_import_param" == "--embed" ]] || [[ "$ub_import_param" == "--return" ]] || [[ "$ub_import_param" == "--devenv" ]])
then
	if ([[ "$scriptAbsoluteLocation" == "" ]] || [[ "$scriptAbsoluteFolder" == "" ]] || [[ "$sessionid" == "" ]]) && _messagePlain_bad 'import: parent: missing: scriptAbsoluteLocation, missing: scriptAbsoluteFolder, missing: sessionid' | _user_log-ub
	then
		return 1 >/dev/null 2>&1
		exit 1
	fi
elif [[ "$ub_import_param" == "--call" ]] || [[ "$ub_import_param" == "--script" ]] || [[ "$ub_import_param" == "--bypass" ]] || [[ "$ub_import_param" == "--shell" ]] || ([[ "$ub_import" == "true" ]] && [[ "$ub_import_param" == "" ]])
then
	if ([[ "$importScriptLocation" == "" ]] ||  [[ "$importScriptFolder" == "" ]]) && _messagePlain_bad 'import: call: missing: importScriptLocation, missing: importScriptFolder' | _user_log-ub
	then
		return 1 >/dev/null 2>&1
		exit 1
	fi
elif [[ "$ub_import" != "true" ]]	#"--shell", ""
then
	_messagePlain_warn 'import: undetected: cannot determine if imported' | _user_log-ub
	true #no problem
else	#FAIL, implies [[ "$ub_import" == "true" ]]
	_messagePlain_bad 'import: fall: fail' | _user_log-ub
	return 1 >/dev/null 2>&1
	exit 1
fi

#Override.

#Override (Program).

#####Utilities

#Critical prerequsites.
_getAbsolute_criticalDep() {
	! type realpath > /dev/null 2>&1 && return 1
	! type readlink > /dev/null 2>&1 && return 1
	! type dirname > /dev/null 2>&1 && return 1
	
	#Known issue on Mac. See https://github.com/mirage335/ubiquitous_bash/issues/1 .
	! realpath -L . > /dev/null 2>&1 && return 1
	
	return 0
}
! _getAbsolute_criticalDep && exit 1

#Retrieves absolute path of current script, while maintaining symlinks, even when "./" would translate with "readlink -f" into something disregarding symlinked components in $PWD.
#However, will dereference symlinks IF the script location itself is a symlink. This is to allow symlinking to scripts to function normally.
#Suitable for allowing scripts to find other scripts they depend on. May look like an ugly hack, but it has proven reliable over the years.
_getScriptAbsoluteLocation() {
	if [[ "$0" == "-"* ]]
	then
		return 1
	fi
	
	local absoluteLocation
	if [[ (-e $PWD\/$0) && ($0 != "") ]] && [[ "$0" != "/"* ]]
			then
	absoluteLocation="$PWD"\/"$0"
	absoluteLocation=$(realpath -L -s "$absoluteLocation")
			else
	absoluteLocation=$(realpath -L "$0")
	fi

	if [[ -h "$absoluteLocation" ]]
			then
	absoluteLocation=$(readlink -f "$absoluteLocation")
	absoluteLocation=$(realpath -L "$absoluteLocation")
	fi
	echo $absoluteLocation
}
alias getScriptAbsoluteLocation=_getScriptAbsoluteLocation

#Retrieves absolute path of current script, while maintaining symlinks, even when "./" would translate with "readlink -f" into something disregarding symlinked components in $PWD.
#Suitable for allowing scripts to find other scripts they depend on.
_getScriptAbsoluteFolder() {
	if [[ "$0" == "-"* ]]
	then
		return 1
	fi
	
	dirname "$(_getScriptAbsoluteLocation)"
}
alias getScriptAbsoluteFolder=_getScriptAbsoluteFolder

#Retrieves absolute path of parameter, while maintaining symlinks, even when "./" would translate with "readlink -f" into something disregarding symlinked components in $PWD.
#Suitable for finding absolute paths, when it is desirable not to interfere with symlink specified folder structure.
_getAbsoluteLocation() {
	if [[ "$1" == "-"* ]]
	then
		return 1
	fi
	
	if [[ "$1" == "" ]]
	then
		echo
		return
	fi
	
	local absoluteLocation
	if [[ (-e $PWD\/$1) && ($1 != "") ]] && [[ "$1" != "/"* ]]
			then
	absoluteLocation="$PWD"\/"$1"
	absoluteLocation=$(realpath -L -s "$absoluteLocation")
			else
	absoluteLocation=$(realpath -L "$1")
	fi
	echo "$absoluteLocation"
}
alias getAbsoluteLocation=_getAbsoluteLocation

#Retrieves absolute path of parameter, while maintaining symlinks, even when "./" would translate with "readlink -f" into something disregarding symlinked components in $PWD.
#Suitable for finding absolute paths, when it is desirable not to interfere with symlink specified folder structure.
_getAbsoluteFolder() {
	if [[ "$1" == "-"* ]]
	then
		return 1
	fi
	
	local absoluteLocation=$(_getAbsoluteLocation "$1")
	dirname "$absoluteLocation"
}
alias getAbsoluteLocation=_getAbsoluteLocation

_getScriptLinkName() {
	! [[ -e "$0" ]] && return 1
	! [[ -L "$0" ]] && return 1
	
	! type basename > /dev/null 2>&1 && return 1
	
	local scriptLinkName
	scriptLinkName=$(basename "$0")
	
	[[ "$scriptLinkName" == "" ]] && return 1
	echo "$scriptLinkName"
}

#https://unix.stackexchange.com/questions/27021/how-to-name-a-file-in-the-deepest-level-of-a-directory-tree?answertab=active#tab-top
_filter_lowestPath() {
	awk -F'/' 'NF > depth {
depth = NF;
deepest = $0;
}
END {
print deepest;
}'
}

#https://stackoverflow.com/questions/1086907/can-find-or-any-other-tool-search-for-files-breadth-first
_filter_highestPath() {
	awk -F'/' '{print "", NF, $F}' | sort -n | awk '{print $2}' | head -n 1
}

_recursion_guard() {
	! [[ -e "$1" ]] && return 1
	
	! type "$1" >/dev/null 2>&1 && return 1
	
	local launchGuardScriptAbsoluteLocation
	launchGuardScriptAbsoluteLocation=$(_getScriptAbsoluteLocation)
	local launchGuardTestAbsoluteLocation
	launchGuardTestAbsoluteLocation=$(_getAbsoluteLocation "$1")
	[[ "$launchGuardScriptAbsoluteLocation" == "$launchGuardTestAbsoluteLocation" ]] && return 1
	
	return 0
}

#Checks whether command or function is available.
# DANGER Needed by safeRMR .
_checkDep() {
	if ! type "$1" >/dev/null 2>&1
	then
		echo "$1" missing
		_stop 1
	fi
}

_tryExec() {
	type "$1" >/dev/null 2>&1 && "$1"
}

_tryExecFull() {
	type "$1" >/dev/null 2>&1 && "$@"
}

#Fails if critical global variables point to nonexistant locations. Code may be duplicated elsewhere for extra safety.
_failExec() {
	[[ ! -e "$scriptAbsoluteLocation" ]] && return 1
	[[ ! -e "$scriptAbsoluteFolder" ]] && return 1
	return 0
}

#Portable sanity checked "rm -r" command.
# DANGER Last line of defense against catastrophic errors where "rm -r" or similar would be used!
# WARNING Not foolproof. Use to guard against systematic errors, not carelessness.
# WARNING Do NOT rely upon outside of internal programmatic usage inside script!
# WARNING Consider using this function even if program control flow can be proven safe. Redundant checks just might catch catastrophic memory errors.
#"$1" == directory to remove
_safeRMR() {
	! type _getAbsolute_criticalDep > /dev/null 2>&1 && return 1
	! _getAbsolute_criticalDep && return 1
	
	#Fail sooner, avoiding irrelevant error messages. Especially important to cases where an upstream process has already removed the "$safeTmp" directory of a downstream process which reaches "_stop" later.
	! [[ -e "$1" ]] && return 1
	
	[[ ! -e "$scriptAbsoluteLocation" ]] && return 1
	[[ ! -e "$scriptAbsoluteFolder" ]] && return 1
	_failExec || return 1
	
	#if [[ ! -e "$0" ]]
	#then
	#	return 1
	#fi
	
	if [[ "$1" == "" ]]
	then
		return 1
	fi
	
	if [[ "$1" == "/" ]]
	then
		return 1
	fi
	
	if [[ "$1" == "-"* ]]
	then
		return 1
	fi
	
	#Blacklist.
	[[ "$1" == "/home" ]] && return 1
	[[ "$1" == "/home/" ]] && return 1
	[[ "$1" == "/home/$USER" ]] && return 1
	[[ "$1" == "/home/$USER/" ]] && return 1
	[[ "$1" == "/$USER" ]] && return 1
	[[ "$1" == "/$USER/" ]] && return 1
	
	[[ "$1" == "/tmp" ]] && return 1
	[[ "$1" == "/tmp/" ]] && return 1
	
	[[ "$1" == "$HOME" ]] && return 1
	[[ "$1" == "$HOME/" ]] && return 1
	
	#Whitelist.
	local safeToRM=false
	
	local safeScriptAbsoluteFolder
	#safeScriptAbsoluteFolder="$(_getScriptAbsoluteFolder)"
	safeScriptAbsoluteFolder="$scriptAbsoluteFolder"
	
	[[ "$1" == "./"* ]] && [[ "$PWD" == "$safeScriptAbsoluteFolder"* ]] && safeToRM="true"
	
	[[ "$1" == "$safeScriptAbsoluteFolder"* ]] && safeToRM="true"
	
	#[[ "$1" == "/home/$USER"* ]] && safeToRM="true"
	[[ "$1" == "/tmp/"* ]] && safeToRM="true"
	
	[[ "$safeToRM" == "false" ]] && return 1
	
	#Safeguards/
	[[ "$safeToDeleteGit" != "true" ]] && [[ -d "$1" ]] && [[ -e "$1" ]] && find "$1" | grep -i '\.git$' >/dev/null 2>&1 && return 1
	
	#Validate necessary tools were available for path building and checks.
	_checkDep realpath
	_checkDep readlink
	_checkDep dirname
	_checkDep basename
	
	if [[ -e "$1" ]]
	then
		#sleep 0
		#echo "$1"
		# WARNING Recommend against adding any non-portable flags.
		rm -rf "$1"
	fi
}

#Portable sanity checking for less, but, dangerous, commands.
# WARNING Not foolproof. Use to guard against systematic errors, not carelessness.
# WARNING Do NOT rely upon outside of internal programmatic usage inside script!
#"$1" == file/directory path to sanity check
_safePath() {
	! type _getAbsolute_criticalDep > /dev/null 2>&1 && return 1
	! _getAbsolute_criticalDep && return 1
	
	[[ ! -e "$scriptAbsoluteLocation" ]] && return 1
	[[ ! -e "$scriptAbsoluteFolder" ]] && return 1
	_failExec || return 1
	
	#if [[ ! -e "$0" ]]
	#then
	#	return 1
	#fi
	
	if [[ "$1" == "" ]]
	then
		return 1
	fi
	
	if [[ "$1" == "/" ]]
	then
		return 1
	fi
	
	if [[ "$1" == "-"* ]]
	then
		return 1
	fi
	
	#Blacklist.
	[[ "$1" == "/home" ]] && return 1
	[[ "$1" == "/home/" ]] && return 1
	[[ "$1" == "/home/$USER" ]] && return 1
	[[ "$1" == "/home/$USER/" ]] && return 1
	[[ "$1" == "/$USER" ]] && return 1
	[[ "$1" == "/$USER/" ]] && return 1
	
	[[ "$1" == "/tmp" ]] && return 1
	[[ "$1" == "/tmp/" ]] && return 1
	
	[[ "$1" == "$HOME" ]] && return 1
	[[ "$1" == "$HOME/" ]] && return 1
	
	#Whitelist.
	local safeToRM=false
	
	local safeScriptAbsoluteFolder
	#safeScriptAbsoluteFolder="$(_getScriptAbsoluteFolder)"
	safeScriptAbsoluteFolder="$scriptAbsoluteFolder"
	
	[[ "$1" == "./"* ]] && [[ "$PWD" == "$safeScriptAbsoluteFolder"* ]] && safeToRM="true"
	
	[[ "$1" == "$safeScriptAbsoluteFolder"* ]] && safeToRM="true"
	
	#[[ "$1" == "/home/$USER"* ]] && safeToRM="true"
	[[ "$1" == "/tmp/"* ]] && safeToRM="true"
	
	[[ "$safeToRM" == "false" ]] && return 1
	
	#Safeguards/
	[[ "$safeToDeleteGit" != "true" ]] && [[ -d "$1" ]] && [[ -e "$1" ]] && find "$1" | grep -i '\.git$' >/dev/null 2>&1 && return 1
	
	#Validate necessary tools were available for path building and checks.
	_checkDep realpath
	_checkDep readlink
	_checkDep dirname
	_checkDep basename
	
	if [[ -e "$1" ]]
	then
		#sleep 0
		#echo "$1"
		# WARNING Recommend against adding any non-portable flags.
		return 0
	fi
}

# DANGER Last line of defense against catastrophic errors when using "delete" flag with rsync or similar!
_safeBackup() {
	! type _getAbsolute_criticalDep > /dev/null 2>&1 && return 1
	! _getAbsolute_criticalDep && return 1
	
	[[ ! -e "$scriptAbsoluteLocation" ]] && exit 1
	[[ ! -e "$scriptAbsoluteFolder" ]] && exit 1
	
	#Fail sooner, avoiding irrelevant error messages. Especially important to cases where an upstream process has already removed the "$safeTmp" directory of a downstream process which reaches "_stop" later.
	! [[ -e "$1" ]] && return 1
	
	[[ "$1" == "" ]] && return 1
	[[ "$1" == "/" ]] && return 1
	[[ "$1" == "-"* ]] && return 1
	
	[[ "$1" == "/home" ]] && return 1
	[[ "$1" == "/home/" ]] && return 1
	[[ "$1" == "/home/$USER" ]] && return 1
	[[ "$1" == "/home/$USER/" ]] && return 1
	[[ "$1" == "/$USER" ]] && return 1
	[[ "$1" == "/$USER/" ]] && return 1
	
	[[ "$1" == "/root" ]] && return 1
	[[ "$1" == "/root/" ]] && return 1
	[[ "$1" == "/root/$USER" ]] && return 1
	[[ "$1" == "/root/$USER/" ]] && return 1
	[[ "$1" == "/$USER" ]] && return 1
	[[ "$1" == "/$USER/" ]] && return 1
	
	[[ "$1" == "/tmp" ]] && return 1
	[[ "$1" == "/tmp/" ]] && return 1
	
	[[ "$1" == "$HOME" ]] && return 1
	[[ "$1" == "$HOME/" ]] && return 1
	
	! type realpath > /dev/null 2>&1 && return 1
	! type readlink > /dev/null 2>&1 && return 1
	! type dirname > /dev/null 2>&1 && return 1
	! type basename > /dev/null 2>&1 && return 1
	
	return 0
}

# DANGER Last line of defense against catastrophic errors when using "delete" flag with rsync or similar!
# WARNING Intended for direct copy/paste inclusion into independent launch wrapper scripts. Kept here for redundancy as well as example and maintenance.
_command_safeBackup() {
	! type _command_getAbsolute_criticalDep > /dev/null 2>&1 && return 1
	! _command_getAbsolute_criticalDep && return 1
	
	[[ ! -e "$commandScriptAbsoluteLocation" ]] && exit 1
	[[ ! -e "$commandScriptAbsoluteFolder" ]] && exit 1
	
	#Fail sooner, avoiding irrelevant error messages. Especially important to cases where an upstream process has already removed the "$safeTmp" directory of a downstream process which reaches "_stop" later.
	! [[ -e "$1" ]] && return 1
	
	[[ "$1" == "" ]] && return 1
	[[ "$1" == "/" ]] && return 1
	[[ "$1" == "-"* ]] && return 1
	
	[[ "$1" == "/home" ]] && return 1
	[[ "$1" == "/home/" ]] && return 1
	[[ "$1" == "/home/$USER" ]] && return 1
	[[ "$1" == "/home/$USER/" ]] && return 1
	[[ "$1" == "/$USER" ]] && return 1
	[[ "$1" == "/$USER/" ]] && return 1
	
	[[ "$1" == "/root" ]] && return 1
	[[ "$1" == "/root/" ]] && return 1
	[[ "$1" == "/root/$USER" ]] && return 1
	[[ "$1" == "/root/$USER/" ]] && return 1
	[[ "$1" == "/$USER" ]] && return 1
	[[ "$1" == "/$USER/" ]] && return 1
	
	[[ "$1" == "/tmp" ]] && return 1
	[[ "$1" == "/tmp/" ]] && return 1
	
	[[ "$1" == "$HOME" ]] && return 1
	[[ "$1" == "$HOME/" ]] && return 1
	
	! type realpath > /dev/null 2>&1 && return 1
	! type readlink > /dev/null 2>&1 && return 1
	! type dirname > /dev/null 2>&1 && return 1
	! type basename > /dev/null 2>&1 && return 1
	
	return 0
}



#http://stackoverflow.com/questions/687948/timeout-a-command-in-bash-without-unnecessary-delay
_timeout() { ( set +b; sleep "$1" & "${@:2}" & wait -n; r=$?; kill -9 `jobs -p`; exit $r; ) } 

_terminate() {
	local processListFile
	processListFile="$scriptAbsoluteFolder"/.pidlist_$(_uid)
	
	local currentPID
	
	cat "$safeTmp"/.pid >> "$processListFile" 2> /dev/null
	
	while read -r currentPID
	do
		pkill -P "$currentPID"
		kill "$currentPID"
	done < "$processListFile"
	
	rm "$processListFile"
}

_terminateAll() {
	local processListFile
	processListFile="$scriptAbsoluteFolder"/.pidlist_$(_uid)
	
	local currentPID
	
	cat ./w_*/.pid >> "$processListFile" 2> /dev/null
	cat ./.s_*/.pid >> "$processListFile" 2> /dev/null
	
	while read -r currentPID
	do
		pkill -P "$currentPID"
		kill "$currentPID"
	done < "$processListFile"
	
	rm "$processListFile"
}

#Generates random alphanumeric characters, default length 18.
_uid() {
	local uidLength
	! [[ -z "$1" ]] && uidLength="$1" || uidLength=18
	
	cat /dev/urandom 2> /dev/null | base64 2> /dev/null | tr -dc 'a-zA-Z0-9' 2> /dev/null | head -c "$uidLength" 2> /dev/null
}

_permissions_directory_checkForPath() {
	local parameterAbsoluteLocation
	parameterAbsoluteLocation=$(_getAbsoluteLocation "$1")
	
	local checkScriptAbsoluteFolder="$(_getScriptAbsoluteFolder)"
	
	[[ "$parameterAbsoluteLocation" == "$PWD" ]] && ! [[ "$parameterAbsoluteLocation" == "$checkScriptAbsoluteFolder" ]] && return 1
	
	local permissions_readout=$(stat -c "%a" "$1")
	
	local permissions_user
	local permissions_group
	local permissions_other
	
	permissions_user=$(echo "$permissions_readout" | cut -c 1)
	permissions_group=$(echo "$permissions_readout" | cut -c 2)
	permissions_other=$(echo "$permissions_readout" | cut -c 3)
	
	[[ "$permissions_user" -gt "7" ]] && return 1
	[[ "$permissions_group" -gt "7" ]] && return 1
	[[ "$permissions_other" -gt "5" ]] && return 1
	
	#Above checks considered sufficient in typical cases, remainder for sake of example. Return true (safe).
	return 0
	
	local permissions_uid
	local permissions_gid
	
	permissions_uid=$(stat -c "%u" "$1")
	permissions_gid=$(stat -c "%g" "$1")
	
	#Normally these variables are available through ubiqutious bash, but this permissions check may be needed earlier in that global variables setting process.
	local permissions_host_uid
	local permissions_host_gid
	
	permissions_host_uid=$(id -u)
	permissions_host_gid=$(id -g)
	
	[[ "$permissions_uid" != "$permissions_host_uid" ]] && return 1
	[[ "$permissions_uid" != "$permissions_host_gid" ]] && return 1
	
	return 0
}

#Checks whether the repository has unsafe permissions for adding binary files to path. Used as an extra safety check by "_setupUbiquitous" before adding a hook to the user's default shell environment.
_permissions_ubiquitous_repo() {
	local parameterAbsoluteLocation
	parameterAbsoluteLocation=$(_getAbsoluteLocation "$1")
	
	[[ ! -e "$parameterAbsoluteLocation" ]] && return 0
	
	! _permissions_directory_checkForPath "$parameterAbsoluteLocation" && return 1
	
	[[ -e "$parameterAbsoluteLocation"/_bin ]] && ! _permissions_directory_checkForPath "$parameterAbsoluteLocation"/_bin && return 1
	[[ -e "$parameterAbsoluteLocation"/_bundle ]] && ! _permissions_directory_checkForPath "$parameterAbsoluteLocation"/_bundle && return 1
	
	return 0
}

#Checks whether currently set "$scriptBin" and similar locations are actually safe.
# WARNING Keep in mind this is necessarily run only after PATH would already have been modified, and does not guard against threats already present on the local machine.
_test_permissions_ubiquitous() {
	[[ ! -e "$scriptAbsoluteFolder" ]] && _stop 1
	
	! _permissions_directory_checkForPath "$scriptAbsoluteFolder" && _stop 1
	
	[[ -e "$scriptBin" ]] && ! _permissions_directory_checkForPath "$scriptBin" && _stop 1
	[[ -e "$scriptBundle" ]] && ! _permissions_directory_checkForPath "$scriptBundle" && _stop 1
	
	return 0
}



#Takes "$@". Places in global array variable "globalArgs".
# WARNING Adding this globalvariable to the "structure/globalvars.sh" declaration or similar to be overridden at script launch is not recommended.
#"${globalArgs[@]}"
_gather_params() {
	export globalArgs=("${@}")
}

_instance_internal() {
	! [[ -e "$1" ]] && return 1
	! [[ -d "$1" ]] && return 1
	! [[ -e "$2" ]] && return 1
	! [[ -d "$2" ]] && return 1
	rsync -q -ax --exclude "/.cache" --exclude "/.git" "$@"
}

#echo -n
_safeEcho() {
	printf '%s' "$1"
	shift
	
	[[ "$@" == "" ]] && return 0
	
	local currentArg
	for currentArg in "$@"
	do
		printf '%s' " "
		printf '%s' "$currentArg"
	done
	return 0
}

#echo
_safeEcho_newline() {
	_safeEcho "$@"
	printf '\n'
}

#Universal debugging filesystem.
#End user function.
_user_log() {
	# DANGER Do NOT create automatically, or reference any existing directory!
	! [[ -d "$HOME"/.ubcore/userlog ]] && cat - > /dev/null 2>&1 && return 0
	
	cat - >> "$HOME"/.ubcore/userlog/user.log
	
	return 0
}

_monitor_user_log() {
	! [[ -d "$HOME"/.ubcore/userlog ]] && return 1
	
	tail -f "$HOME"/.ubcore/userlog/*
}

#Universal debugging filesystem.
#"generic/ubiquitousheader.sh"
_user_log-ub() {
	# DANGER Do NOT create automatically, or reference any existing directory!
	! [[ -d "$HOME"/.ubcore/userlog ]] && cat - > /dev/null 2>&1 && return 0
	
	#Terminal session may be used - the sessionid may be set through .bashrc/.ubcorerc .
	if [[ "$sessionid" != "" ]]
	then
		cat - >> "$HOME"/.ubcore/userlog/u-"$sessionid".log
		return 0
	fi
	cat - >> "$HOME"/.ubcore/userlog/u-undef.log
	
	return 0
}

_monitor_user_log-ub() {
	! [[ -d "$HOME"/.ubcore/userlog ]] && return 1
	
	tail -f "$HOME"/.ubcore/userlog/u-*
}

#Universal debugging filesystem.
_user_log_anchor() {
	# DANGER Do NOT create automatically, or reference any existing directory!
	! [[ -d "$HOME"/.ubcore/userlog ]] && cat - > /dev/null 2>&1 && return 0
	
	#Terminal session may be used - the sessionid may be set through .bashrc/.ubcorerc .
	if [[ "$sessionid" != "" ]]
	then
		cat - >> "$HOME"/.ubcore/userlog/a-"$sessionid".log
		return 0
	fi
	cat - >> "$HOME"/.ubcore/userlog/a-undef.log
	
	return 0
}

_monitor_user_log_anchor() {
	! [[ -d "$HOME"/.ubcore/userlog ]] && return 1
	
	tail -f "$HOME"/.ubcore/userlog/a-*
}

#Universal debugging filesystem.
_user_log_template() {
	# DANGER Do NOT create automatically, or reference any existing directory!
	! [[ -d "$HOME"/.ubcore/userlog ]] && cat - > /dev/null 2>&1 && return 0
	
	#Terminal session may be used - the sessionid may be set through .bashrc/.ubcorerc .
	if [[ "$sessionid" != "" ]]
	then
		cat - >> "$HOME"/.ubcore/userlog/t-"$sessionid".log
		return 0
	fi
	cat - >> "$HOME"/.ubcore/userlog/t-undef.log
	
	return 0
}

_messageColors() {
	echo -e '\E[1;37m 'white' \E[0m'
	echo -e '\E[0;30m 'black' \E[0m'
	echo -e '\E[0;34m 'blue' \E[0m'
	echo -e '\E[1;34m 'blue_light' \E[0m'
	echo -e '\E[0;32m 'green' \E[0m'
	echo -e '\E[1;32m 'green_light' \E[0m'
	echo -e '\E[0;36m 'cyan' \E[0m'
	echo -e '\E[1;36m 'cyan_light' \E[0m'
	echo -e '\E[0;31m 'red' \E[0m'
	echo -e '\E[1;31m 'red_light' \E[0m'
	echo -e '\E[0;35m 'purple' \E[0m'
	echo -e '\E[1;35m 'purple_light' \E[0m'
	echo -e '\E[0;33m 'brown' \E[0m'
	echo -e '\E[1;33m 'yellow' \E[0m'
	echo -e '\E[0;30m 'gray' \E[0m'
	echo -e '\E[1;37m 'gray_light' \E[0m'
	return 0
}

#Cyan. Harmless status messages.
#"generic/ubiquitousheader.sh"
_messagePlain_nominal() {
	echo -e -n '\E[0;36m '
	echo -n "$@"
	echo -e -n ' \E[0m'
	echo
	return 0
}

#Blue. Diagnostic instrumentation.
#"generic/ubiquitousheader.sh"
_messagePlain_probe() {
	echo -e -n '\E[0;34m '
	echo -n "$@"
	echo -e -n ' \E[0m'
	echo
	return 0
}

#Blue. Diagnostic instrumentation.
#"generic/ubiquitousheader.sh"
_messagePlain_probe_expr() {
	echo -e -n '\E[0;34m '
	echo -e -n "$@"
	echo -e -n ' \E[0m'
	echo
	return 0
}

#Green. Working as expected.
#"generic/ubiquitousheader.sh"
_messagePlain_good() {
	echo -e -n '\E[0;32m '
	echo -n "$@"
	echo -e -n ' \E[0m'
	echo
	return 0
}

#Yellow. May or may not be a problem.
#"generic/ubiquitousheader.sh"
_messagePlain_warn() {
	echo -e -n '\E[1;33m '
	echo -n "$@"
	echo -e -n ' \E[0m'
	echo
	return 0
}

#Red. Will result in missing functionality, reduced performance, etc, but not necessarily program failure overall.
_messagePlain_bad() {
	echo -e -n '\E[0;31m '
	echo -n "$@"
	echo -e -n ' \E[0m'
	echo
	return 0
}

#Demarcate major steps.
_messageNormal() {
	echo -e -n '\E[1;32;46m '
	echo -n "$@"
	echo -e -n ' \E[0m'
	echo
	return 0
}

#Demarcate major failures.
_messageError() {
	echo -e -n '\E[1;33;41m '
	echo -n "$@"
	echo -e -n ' \E[0m'
	echo
	return 0
}

#Demarcate need to fetch/generate dependency automatically - not a failure condition.
_messageNEED() {
	_messageNormal "NEED"
	#echo " NEED "
}

#Demarcate have dependency already, no need to fetch/generate.
_messageHAVE() {
	_messageNormal "HAVE"
	#echo " HAVE "
}

_messageWANT() {
	_messageNormal "WANT"
	#echo " WANT "
}

#Demarcate where PASS/FAIL status cannot be absolutely proven. Rarely appropriate - usual best practice is to simply progress to the next major step.
_messageDONE() {
	_messageNormal "DONE"
	#echo " DONE "
}

_messagePASS() {
	_messageNormal "PASS"
	#echo " PASS "
}

#Major failure. Program stopped.
_messageFAIL() {
	_messageError "FAIL"
	#echo " FAIL "
	_stop 1
}

_messageWARN() {
	echo
	echo "$@"
	return 0
}


_messageProcess() {
	local processString
	processString="$1""..."
	
	local processStringLength
	processStringLength=${#processString}
	
	local currentIteration
	currentIteration=0
	
	local padLength
	let padLength=40-"$processStringLength"
	
	[[ "$processStringLength" -gt "38" ]] && _messageNormal "$processString" && return 0
	
	echo -e -n '\E[1;32;46m '
	
	echo -n "$processString"
	
	echo -e -n '\E[0m'
	
	while [[ "$currentIteration" -lt "$padLength" ]]
	do
		echo -e -n ' '
		let currentIteration="$currentIteration"+1
	done
	
	return 0
}

_mustcarry() {
	grep "$1" "$2" > /dev/null 2>&1 && return 0
	
	echo "$1" >> "$2"
	return
}

#"$1" == file path
_includeFile() {
	
	if [[ -e  "$1" ]]
	then
		cat "$1" >> "$progScript"
		echo >> "$progScript"
		return 0
	fi
	
	return 1
}

#Provide only approximate, realative paths. These will be disassembled and treated as a search query following stricti preferences
#"generic/filesystem/absolutepaths.sh"
_includeScript() {

	local includeScriptFilename=$(basename "$1")
	local includeScriptSubdirectory=$(dirname "$1")
	
	
	_includeFile "$progDir"/"$includeScriptSubdirectory"/"$includeScriptFilename" && return 0
	
	_includeFile "$progDir"/"$includeScriptFilename" && return 0
	
	_includeFile "$ubiquitiousLibDir"/"$includeScriptSubdirectory"/"$includeScriptFilename" && return 0
	
	_includeFile "$ubiquitiousLibDir"/"$includeScriptFilename" && return 0
	
	_includeFile "$configDir"/"$includeScriptFilename" && return 0
	
	#[[ "$configBaseDir" == "" ]] && configBaseDir="_config"
	[[ "$configBaseDir" == "" ]] && configBaseDir=$(basename "$configDir")
	
	_includeFile "$ubiquitiousLibDir"/"$configBaseDir"/"$includeScriptFilename" && return 0
	
	return 1
}

# "$1" == script list array
_includeScripts() {
	local currentIncludeScript
	local historyIncludeScript
	local historyIncludedScript
	local duplicateIncludeScript
	
	for currentIncludeScript in "$@"
	do	
		duplicateIncludeScript="false"
		for historyIncludedScript in "${historyIncludeScript[@]}"
		do
			if [[ "$historyIncludedScript" == "$currentIncludeScript" ]]
			then
				duplicateIncludeScript="true"
			fi
		done
		historyIncludeScript+=("$currentIncludeScript")
		
		[[ "$duplicateIncludeScript" != "true" ]] && _includeScript "$currentIncludeScript"
	done
}

#Gets filename extension, specifically any last three characters in given string.
#"$1" == filename
_getExt() {
	echo "$1" | tr -dc 'a-zA-Z0-9.' | tr '[:upper:]' '[:lower:]' | tail -c 4
}

#Reports either the directory provided, or the directory of the file provided.
_findDir() {
	local dirIn=$(_getAbsoluteLocation "$1")
	dirInLogical=$(realpath -L -s "$dirIn")
	
	if [[ -d "$dirInLogical" ]]
	then
		echo "$dirInLogical"
		return
	fi
	
	echo $(_getAbsoluteFolder "$dirInLogical")
	return
	
}

_discoverResource() {
	
	[[ "$scriptAbsoluteFolder" == "" ]] && return 1
	
	local testDir
	testDir="$scriptAbsoluteFolder" ; [[ -e "$testDir"/"$1" ]] && echo "$testDir"/"$1" && return 0
	testDir="$scriptAbsoluteFolder"/.. ; [[ -e "$testDir"/"$1" ]] && echo "$testDir"/"$1" && return 0
	testDir="$scriptAbsoluteFolder"/../.. ; [[ -e "$testDir"/"$1" ]] && echo "$testDir"/"$1" && return 0
	testDir="$scriptAbsoluteFolder"/../../.. ; [[ -e "$testDir"/"$1" ]] && echo "$testDir"/"$1" && return 0
	
	return 1
}

_rmlink() {
	[[ -h "$1" ]] && rm -f "$1" && return 0
	! [[ -e "$1" ]] && return 0
	return 1
}

#Like "ln -sf", but will not proceed if target is not link and exists (ie. will not erase files).
_relink_sequence() {

	#Do not update correct symlink.
	local existingLinkTarget
	existingLinkTarget=$(readlink "$2")
	[[ "$existingLinkTarget" == "$1" ]] && return 0
	
	! [[ "$relinkRelativeUb" == "true" ]] && _rmlink "$2" && ln -s "$1" "$2" && return 0
	[[ "$relinkRelativeUb" == "true" ]] && _rmlink "$2" && ln -s -r "$1" "$2" && return 0
	
	return 1
}

_relink() {
	[[ "$relinkRelativeUb" == "true" ]] && export relinkRelativeUb=""
	_relink_sequence "$@"
}

_relink_relative() {
	export relinkRelativeUb="true"
	_relink_sequence "$@"
	export relinkRelativeUb=""
	unset relinkRelativeUb
}

#Copies files only if source/destination do match. Keeps files in a completely written state as often as possible.
_cpDiff() {
	! diff "$1" "$2" > /dev/null 2>&1 && cp "$1" "$2"
}

_testBindMountManager() {
	_getDep mount
	_getDep umount
	_getDep mountpoint
	
	if ! mount --help | grep '\-\-bind' >/dev/null 2>&1
	then
		echo "mount missing bind feature"
		_stop 1
	fi
	
	if ! mount --help | grep '\-\-rbind' >/dev/null 2>&1
	then
		echo "mount missing rbind feature"
		_stop 1
	fi
	
}


# WARNING: Requries prior check with _mustGetSudo .
#"$1" == Source
#"$2" == Destination
_bindMountManager() {
	mountpoint "$2" > /dev/null 2>&1 && return 1
	
	if [[ "$1" == "" ]]
	then
		return 1
	fi
	
	if [[ "$1" == "/" ]]
	then
		return 1
	fi
	
	[[ ! -e "$1" ]] && return 1
	
	sudo -n mkdir -p "$2"
	[[ ! -e "$2" ]] && return 1
	
	sudo -n mount --bind "$1" "$2"
} 

_wait_umount() {
	sudo -n umount "$1"
	mountpoint "$1" > /dev/null 2>&1 || return 0
	sleep 0.1
	
	sudo -n umount "$1"
	mountpoint "$1" > /dev/null 2>&1 || return 0
	sleep 0.3
	
	[[ "$EMERGENCYSHUTDOWN" == "true" ]] && return 1
	
	sudo -n umount "$1"
	mountpoint "$1" > /dev/null 2>&1 || return 0
	sleep 1
	
	sudo -n umount "$1"
	mountpoint "$1" > /dev/null 2>&1 || return 0
	sleep 3
	
	sudo -n umount "$1"
	mountpoint "$1" > /dev/null 2>&1 || return 0
	sleep 9
	
	return 1
} 

_testMountChecks() {
	_getDep mountpoint
}

#"$1" == test directory
#"$2" == flag file
_flagMount() {
	# TODO: Possible stability/portability improvements.
	#https://unix.stackexchange.com/questions/248472/finding-mount-points-with-the-find-command
	
	mountpoint "$1" >/dev/null 2>&1 && echo -n true > "$2"
}

#Searches directory for mounted filesystems.
# DANGER Do not drop requirement for sudo. As this function represents a final fail-safe, filesystem permissions cannot be allowed to interfere.
#"$1" == test directory
_checkForMounts() {
	_mustGetSudo || return 0
	
	_start
	
	#If test directory itself is a directory, further testing is not necessary.
	sudo -n mountpoint "$1" > /dev/null 2>&1 && _stop 0
	
	local mountCheckFile="$safeTmp"/mc-$(_uid)
	
	echo -n false > "$mountCheckFile"
	
	#Sanity check, file exists.
	! [[ -e "$mountCheckFile" ]] && _stop 0
	
	# TODO: Possible stability/portability improvements.
	#https://unix.stackexchange.com/questions/248472/finding-mount-points-with-the-find-command
	
	find "$1" -type d -exec sudo -n mountpoint {} 2>/dev/null \; | grep 'is a mountpoint' >/dev/null 2>&1 && echo -n true > "$mountCheckFile"
	
	#find "$1" -type d -exec "$scriptAbsoluteLocation" {} "$mountCheckFile" \;
	
	local includesMount
	includesMount=$(cat "$mountCheckFile")
	
	#Thorough sanity checking.
	[[ "$includesMount" != "false" ]] && _stop 0
	[[ "$includesMount" == "true" ]] && _stop 0
	[[ "$includesMount" == "false" ]] && _stop 1
	
	_stop 0
}

#Waits for the process PID specified by first parameter to end. Useful in conjunction with $! to provide process control and/or PID files. Unlike wait command, does not require PID to be a child of the current shell.
_pauseForProcess() {
	while ps --no-headers -p $1 &> /dev/null
	do
		sleep 0.3
	done
}
alias _waitForProcess=_pauseForProcess
alias waitForProcess=_pauseForProcess

_test_daemon() {
	_getDep pkill
}

#To ensure the lowest descendents are terminated first, the file must be created in reverse order. Additionally, PID files created before a prior reboot must be discarded and ignored.
_prependDaemonPID() {
	
	#Reset locks from before prior reboot.
	_readLocked "$daemonPidFile"lk
	_readLocked "$daemonPidFile"op
	_readLocked "$daemonPidFile"cl
	
	while true
	do
		_createLocked "$daemonPidFile"op && break
		sleep 0.1
	done
	
	#Removes old PID file if not locked during current UNIX session (ie. since latest reboot).  Prevents termination of non-daemon PIDs.
	if ! _readLocked "$daemonPidFile"lk
	then
		rm -f "$daemonPidFile"
		rm -f "$daemonPidFile"t
	fi
	_createLocked "$daemonPidFile"lk
	
	[[ ! -e "$daemonPidFile" ]] && echo >> "$daemonPidFile"
	cat - "$daemonPidFile" >> "$daemonPidFile"t
	mv "$daemonPidFile"t "$daemonPidFile"
	
	rm -f "$daemonPidFile"op
}

#By default, process descendents will be terminated first. Doing so is essential to reaching sub-proesses of sub-scripts, without manual user input.
#https://stackoverflow.com/questions/34438189/bash-sleep-process-not-getting-killed
_daemonSendTERM() {
	#Terminate descendents if parent has not been able to quit.
	pkill -P "$1"
	! ps -p "$1" >/dev/null 2>&1 && return 0
	sleep 0.1
	! ps -p "$1" >/dev/null 2>&1 && return 0
	sleep 0.3
	! ps -p "$1" >/dev/null 2>&1 && return 0
	sleep 2
	! ps -p "$1" >/dev/null 2>&1 && return 0
	sleep 6
	! ps -p "$1" >/dev/null 2>&1 && return 0
	sleep 9
	
	#Kill descendents if parent has not been able to quit.
	pkill -KILL -P "$1"
	! ps -p "$1" >/dev/null 2>&1 && return 0
	sleep 0.1
	! ps -p "$1" >/dev/null 2>&1 && return 0
	sleep 0.3
	! ps -p "$1" >/dev/null 2>&1 && return 0
	sleep 2
	
	#Terminate parent if parent has not been able to quit.
	kill -TERM "$1"
	! ps -p "$1" >/dev/null 2>&1 && return 0
	sleep 0.1
	! ps -p "$1" >/dev/null 2>&1 && return 0
	sleep 0.3
	! ps -p "$1" >/dev/null 2>&1 && return 0
	sleep 2
	
	#Kill parent if parent has not been able to quit.
	kill KILL "$1"
	! ps -p "$1" >/dev/null 2>&1 && return 0
	sleep 0.1
	! ps -p "$1" >/dev/null 2>&1 && return 0
	sleep 0.3
	
	#Failure to immediately kill parent is an extremely rare, serious error.
	ps -p "$1" >/dev/null 2>&1 && return 1
	return 0
}

#No production use.
_daemonSendKILL() {
	pkill -KILL -P "$1"
	kill -KILL "$1"
}

#True if any daemon registered process is running.
_daemonAction() {
	[[ ! -e "$daemonPidFile" ]] && return 1
	
	local currentLine
	local processedLine
	local daemonStatus
	
	while IFS='' read -r currentLine || [[ -n "$currentLine" ]]; do
		processedLine=$(echo "$currentLine" | tr -dc '0-9')
		if [[ "$processedLine" != "" ]] && ps -p "$processedLine" >/dev/null 2>&1
		then
			daemonStatus="up"
			[[ "$1" == "status" ]] && return 0
			[[ "$1" == "terminate" ]] && _daemonSendTERM "$processedLine"
			[[ "$1" == "kill" ]] && _daemonSendKILL "$processedLine"
		fi
	done < "$daemonPidFile"
	
	[[ "$daemonStatus" == "up" ]] && return 0
	return 1
}

_daemonStatus() {
	_daemonAction "status"
}

#No production use.
_waitForTermination() {
	_daemonStatus && sleep 0.1
	_daemonStatus && sleep 0.3
	_daemonStatus && sleep 1
	_daemonStatus && sleep 2
}
alias _waitForDaemon=_waitForTermination

#Kills background process using PID file.
_killDaemon() {
	#Do NOT proceed if PID values may be invalid.
	! _readLocked "$daemonPidFile"lk && return 1
	
	#Do NOT proceed if daemon is starting (opening).
	_readLocked "$daemonPidFile"op && return 1
	
	! _createLocked "$daemonPidFile"cl && return 1
	
	#Do NOT proceed if daemon is starting (opening).
	_readLocked "$daemonPidFile"op && return 1
	
	_daemonAction "terminate"
	
	#Do NOT proceed to detele lock/PID files unless daemon can be confirmed down.
	_daemonStatus && return 1
	
	rm -f "$daemonPidFile" >/dev/null 2>&1
	rm -f "$daemonPidFile"lk
	rm -f "$daemonPidFile"cl
	
	return 0
}

_cmdDaemon() {
	export isDaemon=true
	
	"$@" &
	
	#Any PID which may be part of a daemon may be appended to this file.
	echo "$!" | _prependDaemonPID
}

#Executes self in background (ie. as daemon).
_execDaemon() {
	#_daemonStatus && return 1
	
	_cmdDaemon "$scriptAbsoluteLocation"
}

_launchDaemon() {
	_start
	
	_killDaemon
	
	
	_execDaemon
	while _daemonStatus
	do
		sleep 5
	done
	
	
	
	
	
	_stop
}

#Remote TERM signal wrapper. Verifies script is actually running at the specified PID before passing along signal to trigger an emergency stop.
#"$1" == pidFile
#"$2" == sessionid (optional for cleaning up stale systemd files)
_remoteSigTERM() {
	[[ ! -e "$1" ]] && [[ "$2" != "" ]] && _unhook_systemd_shutdown "$2"
	
	[[ ! -e "$1" ]] && return 0
	
	pidToTERM=$(cat "$1")
	
	kill -TERM "$pidToTERM"
	
	_pauseForProcess "$pidToTERM"
}

_embed_here() {
	cat << CZXWXcRMTo8EmM8i4d
#!/usr/bin/env bash

export scriptAbsoluteLocation="$scriptAbsoluteLocation"
export scriptAbsoluteFolder="$scriptAbsoluteFolder"
export sessionid="$sessionid"
. "$scriptAbsoluteLocation" --embed "\$@"
CZXWXcRMTo8EmM8i4d
}

_embed() {
	export sessionid="$1"
	"$scriptAbsoluteLocation" --embed "$@"
}

#"$@" == URL
_fetch() {
	if type axel > /dev/null 2>&1
	then
		axel "$@"
		return 0
	fi
	
	wget "$@"
	
	return 0
}

_validatePort() {
	[[ "$1" -lt "1024" ]] && return 1
	[[ "$1" -gt "65535" ]] && return 1
	
	return 0
}

_testFindPort() {
	_getDep ss
	
	local machineLowerPort=$(cat /proc/sys/net/ipv4/ip_local_port_range | cut -f1)
	local machineUpperPort=$(cat /proc/sys/net/ipv4/ip_local_port_range | cut -f2)
	
	[[ "$machineLowerPort" -lt "1024" ]] && echo "invalid lower_port" && _stop 1
	[[ "$machineLowerPort" -lt "32768" ]] && echo "warn: low lower_port"
	[[ "$machineLowerPort" -gt "32768" ]] && echo "warn: high lower_port"
	
	[[ "$machineUpperPort" -gt "65535" ]] && echo "invalid upper_port" && _stop 1
	[[ "$machineUpperPort" -gt "60999" ]] && echo "warn: high upper_port"
	[[ "$machineUpperPort" -lt "60999" ]] && echo "warn: low upper_port"
	
	local testFoundPort
	testFoundPort=$(_findPort)
	! _validatePort "$testFoundPort" && echo "invalid port discovery" && _stop 1
}

#True if port open (in use).
_checkPort_local() {
	[[ "$1" == "" ]] && return 1
	
	if ss -lpn | grep ":$1 " > /dev/null 2>&1
	then
		return 0
	fi
	return 1
}

#Waits a reasonable time interval for port to be open (in use).
#"$1" == port
_waitPort_local() {
	local checksDone
	checksDone=0
	while ! _checkPort_local "$1" && [[ "$checksDone" -lt 72 ]]
	do
		let checksDone+=1
		sleep 0.1
	done
	
	local checksDone
	checksDone=0
	while ! _checkPort_local "$1" && [[ "$checksDone" -lt 72 ]]
	do
		let checksDone+=1
		sleep 0.3
	done
	
	local checksDone
	checksDone=0
	while ! _checkPort_local "$1" && [[ "$checksDone" -lt 72 ]]
	do
		let checksDone+=1
		sleep 1
	done
	
	return 0
}


#http://unix.stackexchange.com/questions/55913/whats-the-easiest-way-to-find-an-unused-local-port
_findPort() {
	local lower_port
	local upper_port
	
	lower_port="$1"
	upper_port="$2"
	
	#Non public ports are between 49152-65535 (2^15 + 2^14 to 2^16 − 1).
	#Convention is to assign ports 55000-65499 and 50025-53999 to specialized servers.
	#read lower_port upper_port < /proc/sys/net/ipv4/ip_local_port_range
	[[ "$lower_port" == "" ]] && lower_port=54000
	[[ "$upper_port" == "" ]] && upper_port=54999
	
	local range_port
	local rand_max
	let range_port="upper_port - lower_port"
	let rand_max="range_port / 2"
	
	local portRangeOffset
	portRangeOffset=$RANDOM
	#let "portRangeOffset %= 150"
	let "portRangeOffset %= rand_max"
	
	[[ "$opsautoGenerationMode" == "true" ]] && [[ "$lowestUsedPort" == "" ]] && export lowestUsedPort="$lower_port"
	[[ "$opsautoGenerationMode" == "true" ]] && lower_port="$lowestUsedPort"
	
	! [[ "$opsautoGenerationMode" == "true" ]] && let "lower_port += portRangeOffset"
	
	while true
	do
		for (( currentPort = lower_port ; currentPort <= upper_port ; currentPort++ )); do
			if ! ss -lpn | grep ":$currentPort " > /dev/null 2>&1
			then
				sleep 0.1
				if ! ss -lpn | grep ":$currentPort " > /dev/null 2>&1
				then
					break 2
				fi
			fi
		done
	done
	
	if [[ "$opsautoGenerationMode" == "true" ]]
	then
		local nextUsablePort
		
		let "nextUsablePort = currentPort + 1"
		export lowestUsedPort="$nextUsablePort"
		
	fi
	
	echo "$currentPort"
	
	_validatePort "$currentPort"
}

_test_waitport() {
	_getDep nmap
}

#Checks hostname for open port.
#"$1" == hostname
#"$2" == port
_checkPort() {
	if nmap -Pn "$1" -p "$2" 2> /dev/null | grep open > /dev/null 2>&1
	then
		return 0
	fi
	return 1
}

#Waits a reasonable time interval for port to be open.
#"$1" == hostname
#"$2" == port
_waitPort() {
	_checkPort "$1" "$2" && return 0
	sleep 0.1
	_checkPort "$1" "$2" && return 0
	sleep 0.1
	_checkPort "$1" "$2" && return 0
	sleep 0.1
	_checkPort "$1" "$2" && return 0
	sleep 0.1
	_checkPort "$1" "$2" && return 0
	sleep 0.1
	_checkPort "$1" "$2" && return 0
	sleep 0.1
	_checkPort "$1" "$2" && return 0
	sleep 0.1
	_checkPort "$1" "$2" && return 0
	sleep 0.1
	_checkPort "$1" "$2" && return 0
	sleep 0.3
	_checkPort "$1" "$2" && return 0
	sleep 0.3
	_checkPort "$1" "$2" && return 0
	sleep 0.6
	
	local checksDone
	checksDone=0
	while ! _checkPort "$1" "$2" && [[ "$checksDone" -lt 72 ]]
	do
		let checksDone+=1
		sleep 1
	done
	
	return 0
}

#Run command and output to terminal with colorful formatting. Controlled variant of "bash -v".
_showCommand() {
	echo -e '\E[1;32;46m $ '"$1"' \E[0m'
	"$@"
}

#Validates non-empty request.
_validateRequest() {
	echo -e -n '\E[1;32;46m Validating request '"$1"'...	\E[0m'
	[[ "$1" == "" ]] && echo -e '\E[1;33;41m BLANK \E[0m' && return 1
	echo "PASS"
	return
}

#http://www.commandlinefu.com/commands/view/3584/remove-color-codes-special-characters-with-sed
_nocolor() {
	sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g"
}

_noFireJail() {
	if ( [[ -L /usr/local/bin/"$1" ]] && ls -l /usr/local/bin/"$1" | grep firejail > /dev/null 2>&1 ) || ( [[ -L /usr/bin/"$1" ]] && ls -l /usr/bin/"$1" | grep firejail > /dev/null 2>&1 )
	then
		 _messagePlain_bad 'conflict: firejail: '"$1"
		 return 1
	fi
	
	return 0
}

#Copy log files to "$permaLog" or current directory (default) for analysis.
_preserveLog() {
	if [[ ! -d "$permaLog" ]]
	then
		permaLog="$PWD"
	fi
	
	cp "$logTmp"/* "$permaLog"/ > /dev/null 2>&1
}

_test_os_x11() {
	! _wantDep xset && echo 'warn: xset missing, unable to autodetect'
}

#Default. Overridden where remote machine access is needed (ie. _ssh within _vnc) .
#export permit_x11_override=("$scriptAbsoluteLocation" _ssh -C -o ConnectionAttempts=2 "$@")
#In practice, this override hook no longer has any production use.
_permit_x11() {
	if [[ "$permit_x11_override" != "" ]]
	then
		"${permit_x11_override[@]}" "$@"
		return
	fi
	
	"$@"
}

_report_detect_x11() {
	_messagePlain_probe 'report: _report_detect_x11'
	
	[[ "$destination_DISPLAY" == "" ]] && _messagePlain_warn 'blank: $destination_DISPLAY'
	[[ "$destination_DISPLAY" != "" ]] && _messagePlain_probe 'destination_DISPLAY= '"$destination_DISPLAY"
	
	[[ "$destination_AUTH" == "" ]] && _messagePlain_warn 'blank: $destination_AUTH'
	[[ "$destination_AUTH" != "" ]] && _messagePlain_probe 'destination_AUTH= '"$destination_AUTH"
	
	return 0
}

_detect_x11_displays() {
	_messagePlain_nominal "init: _detect_x11_displays"
	
	local current_XAUTH
	[[ "$1" != "" ]] && current_XAUTH="$1"
	
	local current_DISPLAY
	for (( current_DISPLAY = 0 ; current_DISPLAY <= 12 ; current_DISPLAY++ ))
	do
		export destination_AUTH="$current_XAUTH"
		export destination_DISPLAY=":""$current_DISPLAY"
		
		_messagePlain_probe 'test: _detect_x11_displays: display'
		_report_detect_x11
		
		if _permit_x11 env DISPLAY=:"$current_DISPLAY" XAUTHORITY="$current_XAUTH" xset -q > /dev/null 2>&1
		then
			_messagePlain_good 'found: _detect_x11_displays: working display'
			_report_detect_x11
			return 0
		fi
	done
	_messagePlain_probe 'fail: _detect_x11_displays: working display not found'
	return 1
}

_detect_x11() {
	_messagePlain_nominal "init: _detect_x11"
	
	_messagePlain_nominal "Checking X11 destination variables."
	
	[[ "$destination_DISPLAY" != "" ]] && _messagePlain_warn 'set: $destination_DISPLAY'
	[[ "$destination_AUTH" != "" ]] && _messagePlain_warn 'set: $destination_AUTH'
	if [[ "$destination_DISPLAY" != "" ]] || [[ "$destination_AUTH" != "" ]]
	then
		_report_detect_x11
		return 1
	fi
	
	_messagePlain_nominal "Searching typical X11 display locations"
	export destination_DISPLAY
	export destination_AUTH
	
	if _permit_x11 env DISPLAY=$DISPLAY XAUTHORITY="$XAUTHORITY" xset -q > /dev/null 2>&1
	then
		export destination_DISPLAY="$DISPLAY"
		export destination_AUTH="$XAUTHORITY"
		
		_messagePlain_good 'accept: $DISPLAY $XAUTHORITY'
		_report_detect_x11
		return 0
	fi
	
	if _permit_x11 env DISPLAY=:0 XAUTHORITY="$XAUTHORITY" xset -q > /dev/null 2>&1
	then
		export destination_DISPLAY=":0"
		export destination_AUTH="$XAUTHORITY"
		
		_messagePlain_good 'accept: $DISPLAY=:0 $XAUTHORITY'
		_report_detect_x11
		return 0
	fi
	
	if _permit_x11 env DISPLAY=:10 XAUTHORITY="$XAUTHORITY" xset -q > /dev/null 2>&1
	then
		export destination_DISPLAY=":10"
		export destination_AUTH="$XAUTHORITY"
		
		_messagePlain_good 'accept: $DISPLAY=:10 $XAUTHORITY'
		_report_detect_x11
		return 0
	fi
	
	export destination_AUTH=$(ps -eo args -fp $(pgrep Xorg | head -n 1) 2>/dev/null | tail -n+2 | sort | sed 's/.*X.*\-auth\ \(.*\)/\1/' | sed 's/\ \-.*//g')
	_messagePlain_nominal "Searching X11 display locations, from process list"
	_messagePlain_probe 'destination_AUTH= '"$destination_AUTH"
	[[ -e "$destination_AUTH" ]] && _detect_x11_displays "$destination_AUTH" && _messagePlain_good 'return: _detect_x11' && _report_detect_x11 && return 0
	
	export destination_AUTH="$HOME"/.Xauthority
	_messagePlain_nominal "Searching X11 display locations, XAUTHORITY at HOME."
	_messagePlain_probe 'destination_AUTH= '"$destination_AUTH"
	[[ -e "$destination_AUTH" ]] && _detect_x11_displays "$destination_AUTH" && _messagePlain_good 'return: _detect_x11' && _report_detect_x11 && return 0
	
	export destination_AUTH="$XAUTHORITY"
	_messagePlain_nominal "Searching X11 display locations, XAUTHORITY as set."
	_messagePlain_probe 'destination_AUTH= '"$destination_AUTH"
	_detect_x11_displays "$destination_AUTH" && _messagePlain_good 'return: _detect_x11' && _report_detect_x11 && return 0
	
	#Unreliable, extra dependencies, last resort.
	local destination_AUTH
	_wantDep x11vnc && export destination_DISPLAY=$(x11vnc -findauth -finddpy | cut -f1 -d\, | cut -f2- -d\=) && destination_AUTH=$(x11vnc -display "$destination_DISPLAY" -findauth | cut -f2- -d\=)
	_messagePlain_nominal "Searching X11 display locations, from x11vnc"
	_messagePlain_probe 'destination_AUTH= '"$destination_AUTH"
	[[ -e "$destination_AUTH" ]] && export destination_AUTH="$destination_AUTH" && _messagePlain_good 'return: _detect_x11' && _report_detect_x11 && return 0
	
	
	export destination_AUTH=""
	export destination_DISPLAY=""
	
	_report_detect_x11
	_messagePlain_bad 'fail: working display not found'
	return 1
}

_typeDep() {
	[[ -e /lib/"$1" ]] && return 0
	[[ -e /lib/x86_64-linux-gnu/"$1" ]] && return 0
	[[ -e /lib64/"$1" ]] && return 0
	[[ -e /lib64/x86_64-linux-gnu/"$1" ]] && return 0
	[[ -e /usr/lib/"$1" ]] && return 0
	[[ -e /usr/lib/x86_64-linux-gnu/"$1" ]] && return 0
	[[ -e /usr/local/lib/"$1" ]] && return 0
	[[ -e /usr/local/lib/x86_64-linux-gnu/"$1" ]] && return 0
	[[ -e /usr/include/"$1" ]] && return 0
	[[ -e /usr/local/include/"$1" ]] && return 0
	
	if ! type "$1" >/dev/null 2>&1
	then
		return 1
	fi
	
	return 0
}

_wantDep() {
	_typeDep "$1" && return 0
	
	_wantSudo && sudo -n "$scriptAbsoluteLocation" _typeDep "$1" && return 0
	
	return 1
}

_mustGetDep() {
	_typeDep "$1" && return 0
	
	_wantSudo && sudo -n "$scriptAbsoluteLocation" _typeDep "$1" && return 0
	
	echo "$1" missing
	_stop 1
}

_fetchDep_distro() {
	if [[ -e /etc/issue ]] && cat /etc/issue | grep 'Debian' > /dev/null 2>&1
	then
		_tryExecFull _fetchDep_debian "$@"
		return
	fi
	return 1
}

_wantGetDep() {
	_wantDep "$@" && return 0
	
	_fetchDep_distro "$@"
	
	_wantDep "$@" && return 0
	return 1
}

_getDep() {
	_wantDep "$@" && return 0
	
	_fetchDep_distro "$@"
	
	_mustGetDep "$@"
}

_apt-file_sequence() {
	_start
	
	_mustGetSudo
	#_mustGetDep su
	
	! _wantDep apt-file && sudo -n apt-get install --install-recommends -y apt-file
	_checkDep apt-file
	
	sudo -n apt-file "$@" > "$safeTmp"/pkgsOut 2> "$safeTmp"/pkgsErr
	sudo -n apt-file search bash > "$safeTmp"/checkOut 2> "$safeTmp"/checkErr
	
	while ! [[ -s "$safeTmp"/checkOut ]] || cat "$safeTmp"/pkgsErr | grep 'cache is empty' > /dev/null 2>&1
	do
		sudo -n apt-file update > "$safeTmp"/updateOut 2> "$safeTmp"/updateErr
		sudo -n apt-file "$@" > "$safeTmp"/pkgsOut 2> "$safeTmp"/pkgsErr
		sudo -n apt-file search bash > "$safeTmp"/checkOut 2> "$safeTmp"/checkErr
	done
	
	cat "$safeTmp"/pkgsOut
	#cat "$safeTmp"/pkgsErr >&2
	_stop
}

_apt-file() {
	_timeout 750 "$scriptAbsoluteLocation" _apt-file_sequence "$@"
}

_fetchDep_debianStretch_special() {
	if [[ "$1" == *"wine"* ]] && ! dpkg --print-foreign-architectures | grep i386 > /dev/null 2>&1
	then
		sudo -n dpkg --add-architecture i386
		sudo -n apt-get update
		sudo -n apt-get install --install-recommends -y wine
		return 0
	fi
	
	if [[ "$1" == "realpath" ]] || [[ "$1" == "readlink" ]] || [[ "$1" == "dirname" ]] || [[ "$1" == "basename" ]] || [[ "$1" == "sha512sum" ]] || [[ "$1" == "sha256sum" ]] || [[ "$1" == "head" ]] || [[ "$1" == "tail" ]] || [[ "$1" == "sleep" ]] || [[ "$1" == "env" ]] || [[ "$1" == "cat" ]] || [[ "$1" == "mkdir" ]] || [[ "$1" == "dd" ]] || [[ "$1" == "rm" ]] || [[ "$1" == "ln" ]] || [[ "$1" == "ls" ]] || [[ "$1" == "test" ]] || [[ "$1" == "true" ]] || [[ "$1" == "false" ]]
	then
		sudo -n apt-get install --install-recommends -y coreutils
		return 0
	fi
	
	if [[ "$1" == "mount" ]] || [[ "$1" == "umount" ]] || [[ "$1" == "losetup" ]]
	then
		sudo -n apt-get install --install-recommends -y mount
		return 0
	fi
	
	if [[ "$1" == "mountpoint" ]] || [[ "$1" == "mkfs" ]]
	then
		sudo -n apt-get install --install-recommends -y util-linux
		return 0
	fi
	
	if [[ "$1" == "mkfs.ext4" ]]
	then
		sudo -n apt-get install --install-recommends -y e2fsprogs
		return 0
	fi
	
	if [[ "$1" == "parted" ]] || [[ "$1" == "partprobe" ]]
	then
		sudo -n apt-get install --install-recommends -y parted
		return 0
	fi
	
	if [[ "$1" == "qemu-arm-static" ]] || [[ "$1" == "qemu-armeb-static" ]]
	then
		sudo -n apt-get install --install-recommends -y qemu qemu-user-static binfmt-support
		#update-binfmts --display
		return 0
	fi
	
	if [[ "$1" == "qemu-system-x86_64" ]]
	then
		sudo -n apt-get install --install-recommends -y qemu-system-x86
		return 0
	fi
	
	if [[ "$1" == "qemu-img" ]]
	then
		sudo -n apt-get install --install-recommends -y qemu-utils
		return 0
	fi
	
	if [[ "$1" == "VirtualBox" ]] || [[ "$1" == "VBoxSDL" ]] || [[ "$1" == "VBoxManage" ]] || [[ "$1" == "VBoxHeadless" ]]
	then
		sudo -n mkdir -p /etc/apt/sources.list.d
		echo 'deb http://download.virtualbox.org/virtualbox/debian stretch contrib' | sudo -n tee /etc/apt/sources.list.d/vbox.list > /dev/null 2>&1
		
		"$scriptAbsoluteLocation" _getDep wget
		! _wantDep wget && return 1
		
		# TODO Check key fingerprints match "B9F8 D658 297A F3EF C18D  5CDF A2F6 83C5 2980 AECF" and "7B0F AB3A 13B9 0743 5925  D9C9 5442 2A4B 98AB 5139" respectively.
		wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo -n apt-key add -
		wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo -n apt-key add -
		
		sudo -n apt-get update
		sudo -n apt-get install --install-recommends -y dkms virtualbox-5.2
		
		return 0
	fi
	
	if [[ "$1" == "gpg" ]]
	then
		sudo -n apt-get install --install-recommends -y gnupg
		return 0
	fi
	
	#Unlikely scenario for hosts.
	if [[ "$1" == "grub-install" ]]
	then
		sudo -n apt-get install --install-recommends -y grub2
		#sudo -n apt-get install --install-recommends -y grub-legacy
		return 0
	fi
	
	if [[ "$1" == "MAKEDEV" ]]
	then
		sudo -n apt-get install --install-recommends -y makedev
		return 0
	fi
	
	if [[ "$1" == "fgrep" ]]
	then
		sudo -n apt-get install --install-recommends -y grep
		return 0
	fi
	
	if [[ "$1" == "fgrep" ]]
	then
		sudo -n apt-get install --install-recommends -y grep
		return 0
	fi
	
	if [[ "$1" == "awk" ]]
	then
		sudo -n apt-get install --install-recommends -y mawk
		return 0
	fi
	
	if [[ "$1" == "kill" ]] || [[ "$1" == "ps" ]]
	then
		sudo -n apt-get install --install-recommends -y procps
		return 0
	fi
	
	if [[ "$1" == "find" ]]
	then
		sudo -n apt-get install --install-recommends -y findutils
		return 0
	fi
	
	if [[ "$1" == "docker" ]]
	then
		sudo apt-get install --install-recommends -y apt-transport-https ca-certificates curl gnupg2 software-properties-common
		
		"$scriptAbsoluteLocation" _getDep curl
		! _wantDep curl && return 1
		
		curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | sudo -n apt-key add -
		local aptKeyFingerprint
		aptKeyFingerprint=$(sudo -n apt-key fingerprint 0EBFCD88 2> /dev/null)
		[[ "$aptKeyFingerprint" == "" ]] && return 1
		
		sudo -n add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") $(lsb_release -cs) stable"
		
		sudo -n apt-get update
		
		sudo -n apt-get remove -y docker docker-engine docker.io docker-ce docker
		sudo -n apt-get install --install-recommends -y docker-ce
		
		sudo -n usermod -a -G docker "$USER"
		
		return 0
	fi
	
	if [[ "$1" == "smbd" ]]
	then
		sudo -n apt-get install --install-recommends -y samba
		return 0
	fi
	
	if [[ "$1" == "atom" ]]
	then
		curl -L https://packagecloud.io/AtomEditor/atom/gpgkey | sudo -n apt-key add -
		sudo -n sh -c 'echo "deb [arch=amd64] https://packagecloud.io/AtomEditor/atom/any/ any main" > /etc/apt/sources.list.d/atom.list'
		
		sudo -n apt-get update
		
		sudo -n apt-get install --install-recommends -y atom
		
		return 0
	fi
	
	if [[ "$1" == "GL/gl.h" ]] || [[ "$1" == "GL/glext.h" ]] || [[ "$1" == "GL/glx.h" ]] || [[ "$1" == "GL/glxext.h" ]] || [[ "$1" == "GL/dri_interface.h" ]] || [[ "$1" == "x86_64-linux-gnu/pkgconfig/dri.pc" ]]
	then
		sudo -n apt-get install --install-recommends -y mesa-common-dev
		
		return 0
	fi
	
	if [[ "$1" == "go" ]]
	then
		sudo -n apt-get install --install-recommends -y golang-go
		
		return 0
	fi
	
	if [[ "$1" == "cura-lulzbot" ]]
	then
		#Testing/Sid only as of Stretch release cycle.
		#sudo -n apt-get install --install-recommends -y rustc cargo
		
		echo "Requires manual installation. See https://www.lulzbot.com/learn/tutorials/cura-lulzbot-edition-installation-debian ."
cat << 'CZXWXcRMTo8EmM8i4d'
wget -qO - https://download.alephobjects.com/ao/aodeb/aokey.pub | sudo apt-key add -
sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak && sudo sed -i '$a deb http://download.alephobjects.com/ao/aodeb jessie main' /etc/apt/sources.list && sudo apt-get update && sudo apt-get install cura-lulzbot
CZXWXcRMTo8EmM8i4d
		echo "(typical)"
		_stop 1
	fi
	
	if [[ "$1" =~ "FlashPrint" ]]
	then
		#Testing/Sid only as of Stretch release cycle.
		#sudo -n apt-get install --install-recommends -y rustc cargo
		
		echo "Requires manual installation. See http://www.flashforge.com/support-center/flashprint-support/ ."
		_stop 1
	fi
	
	if [[ "$1" == "cargo" ]] || [[ "$1" == "rustc" ]]
	then
		#Testing/Sid only as of Stretch release cycle.
		#sudo -n apt-get install --install-recommends -y rustc cargo
		
		echo "Requires manual installation."
cat << 'CZXWXcRMTo8EmM8i4d'
curl https://sh.rustup.rs -sSf | sh
echo '[[ -e "$HOME"/.cargo/bin ]] && export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
CZXWXcRMTo8EmM8i4d
		echo "(typical)"
		_stop 1
	fi
	
	if [[ "$1" == "firejail" ]]
	then
		echo "WARNING: Recommend manual system configuration after install. See https://firejail.wordpress.com/download-2/ ."
		echo "WARNING: Desktop override symlinks may cause problems, especially preventing proxy host jumping by CoreAutoSSH!"
		return 1
	fi
	
	
	return 1
}

_fetchDep_debianStretch_sequence() {
	_start
	
	_mustGetSudo
	
	_wantDep "$1" && _stop 0
	
	_fetchDep_debianStretch_special "$@" && _wantDep "$1" && _stop 0
	
	sudo -n apt-get install --install-recommends -y "$1" && _wantDep "$1" && _stop 0
	
	_apt-file search "$1" > "$safeTmp"/pkgsOut 2> "$safeTmp"/pkgsErr
	
	local sysPathAll
	sysPathAll=$(sudo -n bash -c "echo \$PATH")
	sysPathAll="$PATH":"$sysPathAll"
	local sysPathArray
	IFS=':' read -r -a sysPathArray <<< "$sysPathAll"
	
	local currentSysPath
	local matchingPackageFile
	local matchingPackagePattern
	local matchingPackage
	for currentSysPath in "${sysPathArray[@]}"
	do
		matchingPackageFile=""
		matchingPackagePath=""
		matchingPackage=""
		matchingPackagePattern="$currentSysPath"/"$1"
		matchingPackageFile=$(grep ': '$matchingPackagePattern'$' "$safeTmp"/pkgsOut | cut -f2- -d' ')
		matchingPackage=$(grep ': '$matchingPackagePattern'$' "$safeTmp"/pkgsOut | cut -f1 -d':')
		if [[ "$matchingPackage" != "" ]]
		then
			sudo -n apt-get install --install-recommends -y "$matchingPackage"
			_wantDep "$1" && _stop 0
		fi
	done
	matchingPackage=""
	matchingPackage=$(head -n 1 "$safeTmp"/pkgsOut | cut -f1 -d':')
	sudo -n apt-get install --install-recommends -y "$matchingPackage"
	_wantDep "$1" && _stop 0
	
	_stop 1
}

_fetchDep_debianStretch() {
	#Run up to 2 times. On rare occasion, cache will become unusable again by apt-find before an installation can be completed. Overall, apt-find is the single weakest link in the system.
	"$scriptAbsoluteLocation" _fetchDep_debianStretch_sequence "$@"
	"$scriptAbsoluteLocation" _fetchDep_debianStretch_sequence "$@"
}

_fetchDep_debian() {
	if [[ -e /etc/debian_version ]] && cat /etc/debian_version | head -c 1 | grep 9 > /dev/null 2>&1
	then
		_fetchDep_debianStretch "$@"
		return
	fi
	
	return 1
}

#https://unix.stackexchange.com/questions/39226/how-to-run-a-script-with-systemd-right-before-shutdown


_here_systemd_shutdown_action() {

cat << 'CZXWXcRMTo8EmM8i4d'
[Unit]
Description=...

[Service]
Type=oneshot
RemainAfterExit=true
ExecStart=/bin/true
CZXWXcRMTo8EmM8i4d

echo ExecStop="$scriptAbsoluteLocation" "$@"

cat << 'CZXWXcRMTo8EmM8i4d'

[Install]
WantedBy=multi-user.target
CZXWXcRMTo8EmM8i4d

}

_here_systemd_shutdown() {

cat << 'CZXWXcRMTo8EmM8i4d'
[Unit]
Description=...

[Service]
Type=oneshot
RemainAfterExit=true
CZXWXcRMTo8EmM8i4d

echo ExecStop="$scriptAbsoluteLocation" _remoteSigTERM "$safeTmp"/.pid "$sessionid"

cat << 'CZXWXcRMTo8EmM8i4d'

[Install]
WantedBy=multi-user.target
CZXWXcRMTo8EmM8i4d

}

_hook_systemd_shutdown() {
	[[ -e /etc/systemd/system/"$sessionid".service ]] && return 0
	
	! _wantSudo && return 1
	
	! [[ -e /etc/systemd/system ]] && return 0
	
	_here_systemd_shutdown | sudo -n tee /etc/systemd/system/"$sessionid".service > /dev/null
	sudo -n systemctl enable "$sessionid".service 2>&1 | sudo tee -a "$permaLog"/gsysd.log > /dev/null 2>&1
	sudo -n systemctl start "$sessionid".service 2>&1 | sudo tee -a "$permaLog"/gsysd.log > /dev/null 2>&1
}

_hook_systemd_shutdown_action() {
	[[ -e /etc/systemd/system/"$sessionid".service ]] && return 0
	
	! _wantSudo && return 1
	
	! [[ -e /etc/systemd/system ]] && return 0
	
	_here_systemd_shutdown_action "$@" | sudo -n tee /etc/systemd/system/"$sessionid".service > /dev/null
	sudo -n systemctl enable "$sessionid".service 2>&1 | sudo tee -a "$permaLog"/gsysd.log > /dev/null 2>&1
	sudo -n systemctl start "$sessionid".service 2>&1 | sudo tee -a "$permaLog"/gsysd.log > /dev/null 2>&1
	
}

#"$1" == sessionid (optional override for cleaning up stale systemd files)
_unhook_systemd_shutdown() {
	local hookSessionid
	hookSessionid="$sessionid"
	[[ "$1" != "" ]] && hookSessionid="$1"
	
	[[ ! -e /etc/systemd/system/"$hookSessionid".service ]] && return 0
	
	! _wantSudo && return 1
	
	! [[ -e /etc/systemd/system ]] && return 0
	
	[[ "$SYSTEMCTLDISABLE" == "true" ]] && echo SYSTEMCTLDISABLE | sudo tee -a "$permaLog"/gsysd.log > /dev/null 2>&1 && return 0
	export SYSTEMCTLDISABLE=true
	
	sudo -n systemctl disable "$hookSessionid".service 2>&1 | sudo tee -a "$permaLog"/gsysd.log > /dev/null 2>&1
	sudo -n rm -f /etc/systemd/system/"$hookSessionid".service 2>&1 | sudo tee -a "$permaLog"/gsysd.log > /dev/null 2>&1
}

#Determines if user is root. If yes, then continue. If not, exits after printing error message.
_mustBeRoot() {
if [[ $(id -u) != 0 ]]; then 
	echo "This must be run as root!"
	exit
fi
}
alias mustBeRoot=_mustBeRoot

#Determines if sudo is usable by scripts.
_mustGetSudo() {
	local rootAvailable
	rootAvailable=false
	
	rootAvailable=$(sudo -n echo true)
	
	#[[ $(id -u) == 0 ]] && rootAvailable=true
	
	! [[ "$rootAvailable" == "true" ]] && exit 1
	
	return 0
}

#Determines if sudo is usable by scripts. Will not exit on failure.
_wantSudo() {
	local rootAvailable
	rootAvailable=false
	
	rootAvailable=$(sudo -n echo true 2> /dev/null)
	
	#[[ $(id -u) == 0 ]] && rootAvailable=true
	
	! [[ "$rootAvailable" == "true" ]] && return 1
	
	return 0
}

#####Idle

_gosuBinary() {
	echo "$hostArch" | grep x86_64 > /dev/null 2>&1 && export gosuBinary="gosu-amd64" && return
	echo "$hostArch" | grep x86 > /dev/null 2>&1 && export gosuBinary="gosu-i386" && return
	echo "$hostArch" | grep arm > /dev/null 2>&1 && export gosuBinary="gosu-armel" && return
	
	uname -m | grep x86_64 > /dev/null 2>&1 && export gosuBinary="gosu-amd64" && return
	uname -m | grep x86 > /dev/null 2>&1 && export gosuBinary="gosu-i386" && return
	uname -m | grep arm > /dev/null 2>&1 && export gosuBinary="gosu-armel" && return
}

_gosuExecVirt() {
	_gosuBinary
	
	if [[ "$1" == "" ]]
	then
		exec "$scriptBin"/"$gosuBinary" "$virtSharedUser" /bin/bash "$@"
		return
	fi
	
	exec "$scriptBin"/"$gosuBinary" "$virtSharedUser" "$@"
}

_test_buildGoSu() {
	_getDep gpg
	_getDep dirmngr
}

_testBuiltGosu() {
	#export PATH="$PATH":"$scriptBin"
	
	_getDep gpg
	_getDep dirmngr
	
	_gosuBinary
	
	_checkDep "$gosuBinary"
	
	#Beware, this test requires either root or sudo to actually verify functionality.
	if ! "$scriptBin"/"$gosuBinary" "$USER" true >/dev/null 2>&1 && ! sudo -n "$scriptBin"/"$gosuBinary" "$USER" true >/dev/null 2>&1
	then
		echo gosu invalid response
		_stop 1
	fi
	
}

_verifyGosu_sequence() {
	_start
	
	local gpgTestDir
	gpgTestDir="$safeTmp"
	[[ -e "$scriptBin"/gosu-armel ]] && [[ -e "$scriptBin"/gosu-armel.asc ]] && [[ -e "$scriptBin"/gosu-amd64 ]] && [[ -e "$scriptBin"/gosu-amd64.asc ]] && [[ -e "$scriptBin"/gosu-i386 ]] && [[ -e "$scriptBin"/gosu-i386.asc ]] && [[ -e "$scriptBin"/gosudev.asc ]] && gpgTestDir="$scriptBin" #&& _stop 1
	
	[[ "$1" != "" ]] && gpgTestDir="$1"
	
	if ! [[ -e "$gpgTestDir"/gosu-armel ]] || ! [[ -e "$gpgTestDir"/gosu-armel.asc ]] || ! [[ -e "$gpgTestDir"/gosu-amd64 ]] || ! [[ -e "$gpgTestDir"/gosu-amd64.asc ]] || ! [[ -e "$gpgTestDir"/gosu-i386 ]] || ! [[ -e "$gpgTestDir"/gosu-i386.asc ]] || ! [[ -e "$gpgTestDir"/gosudev.asc ]]
	then
		_stop 1
	fi
	
	# verify the signature
	export GNUPGHOME="$shortTmp"/vgosu
	mkdir -m 700 -p "$GNUPGHOME" > /dev/null 2>&1
	mkdir -p "$GNUPGHOME"
	chmod 700 "$shortTmp"/vgosu
	
	# TODO Add further verification steps.
	gpg --armor --import "$gpgTestDir"/gosudev.asc || _stop 1
	
	gpg --batch --verify "$gpgTestDir"/gosu-armel.asc "$gpgTestDir"/gosu-armel || _stop 1
	gpg --batch --verify "$gpgTestDir"/gosu-amd64.asc "$gpgTestDir"/gosu-amd64 || _stop 1
	gpg --batch --verify "$gpgTestDir"/gosu-i386.asc "$gpgTestDir"/gosu-i386 || _stop 1
	
	_stop
}

_verifyGosu() {
	if ! "$scriptAbsoluteLocation" _verifyGosu_sequence "$@"
	then
		return 1
	fi
	return 0
}

_testGosu() {
	if ! _verifyGosu > /dev/null 2>&1
	then
		echo 'need valid gosu'
		_stop 1
	fi
	return 0
}

#From https://github.com/tianon/gosu/blob/master/INSTALL.md .
# TODO Build locally from git repo and verify.
_buildGosu_sequence() {
	_start
	
	local haveGosuBin
	haveGosuBin=false
	[[ -e "$scriptBin"/gosu-armel ]] && [[ -e "$scriptBin"/gosu-armel.asc ]] && [[ -e "$scriptBin"/gosu-amd64 ]] && [[ -e "$scriptBin"/gosu-amd64.asc ]] && [[ -e "$scriptBin"/gosu-i386 ]] && [[ -e "$scriptBin"/gosu-i386.asc ]] && [[ -e "$scriptBin"/gosudev.asc ]] && haveGosuBin=true #&& return 0
	
	local GOSU_VERSION
	GOSU_VERSION=1.10
	
	if [[ "$haveGosuBin" != "true" ]]
	then
		wget -O "$safeTmp"/gosu-armel https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-armel
		wget -O "$safeTmp"/gosu-armel.asc https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-armel.asc
		
		wget -O "$safeTmp"/gosu-amd64 https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-amd64
		wget -O "$safeTmp"/gosu-amd64.asc https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-amd64.asc
		
		wget -O "$safeTmp"/gosu-i386 https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-i386
		wget -O "$safeTmp"/gosu-i386.asc https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-i386.asc
	fi
	
	export GNUPGHOME="$shortTmp"/bgosu
	mkdir -m 700 -p "$GNUPGHOME" > /dev/null 2>&1
	mkdir -p "$GNUPGHOME"
	chmod 700 "$shortTmp"/bgosu
	gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 || _stop 1
	gpg --armor --export 036A9C25BF357DD4 > "$safeTmp"/gosudev.asc || stop 1
	
	if [[ "$haveGosuBin" != "true" ]]
	then
		_verifyGosu "$safeTmp" > /dev/null 2>&1 || _stop 1
	fi
	if [[ "$haveGosuBin" == "true" ]]
	then
		_verifyGosu "$scriptBin" > /dev/null 2>&1 || _stop 1
	fi
	
	[[ "$haveGosuBin" != "true" ]] && mv "$safeTmp"/gosu* "$scriptBin"/
	[[ "$haveGosuBin" != "true" ]] && chmod ugoa+rx "$scriptBin"/gosu-*
	
	_stop
}

_buildGosu() {
	"$scriptAbsoluteLocation" _buildGosu_sequence "$@"
}

#Returns a UUID in the form of xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
_getUUID() {
	cat /proc/sys/kernel/random/uuid
}
alias getUUID=_getUUID

_test_bashdb() {
	#_getDep ddd
	
	#if ! _discoverResource bashdb-code/bashdb.sh > /dev/null 2>&1
	#then
	#	echo
	#	echo 'bashdb required for debugging'
		#_stop 1
	#fi
	
	if ! type bashdb > /dev/null 2>&1
	then
		echo
		echo 'warn: bashdb required for debugging'
	#_stop 1
	fi
	
	return 0
}


_stopwatch() {
	local measureDateA
	local measureDateB
	
	measureDateA=$(date +%s%N | cut -b1-13)

	"$@"

	measureDateB=$(date +%s%N | cut -b1-13)

	bc <<< "$measureDateB - $measureDateA"
}


_start_virt_instance() {
	
	mkdir -p "$instancedVirtDir" || return 1
	mkdir -p "$instancedVirtFS" || return 1
	mkdir -p "$instancedVirtTmp" || return 1
	
	mkdir -p "$instancedVirtHome" || return 1
	###mkdir -p "$instancedVirtHomeRef" || return 1
	
	mkdir -p "$sharedHostProjectDir" > /dev/null 2>&1
	mkdir -p "$instancedProjectDir" || return 1
	
}

_start_virt_all() {
	
	_start_virt_instance
	
	mkdir -p "$globalVirtDir" || return 1
	mkdir -p "$globalVirtFS" || return 1
	mkdir -p "$globalVirtTmp" || return 1
	
	
	return 0
}

_stop_virt_instance() {
	
	_wait_umount "$instancedProjectDir"
	sudo -n rmdir "$instancedProjectDir"
	
	_wait_umount "$instancedVirtHome"
	sudo -n rmdir "$instancedVirtHome"
	###_wait_umount "$instancedVirtHomeRef"
	###sudo -n rmdir "$instancedVirtHomeRef"
	sudo -n rmdir "$instancedVirtFS"/home
	
	_wait_umount "$instancedVirtFS"
	sudo -n rmdir "$instancedVirtFS"
	_wait_umount "$instancedVirtTmp"
	sudo -n rmdir "$instancedVirtTmp"
	_wait_umount "$instancedVirtDir"
	sudo -n rmdir "$instancedVirtDir"
	
	
	
	return 0
	
}

_stop_virt_all() {
	
	_stop_virt_instance || return 1
	
	_wait_umount "$globalVirtFS" || return 1
	_wait_umount "$globalVirtTmp" || return 1
	_wait_umount "$globalVirtDir" || return 1
	
	
	
}


#Triggers before "user" and "edit" virtualization commands, to allow a single installation of a virtual machine to be used by multiple ubiquitous labs.
#Does NOT trigger for all non-user commands (eg. open, docker conversion), as these are intended for developers with awareness of associated files under "$scriptLocal".

# WARNING
# DISABLED by default. Must be explicitly enabled by setting "$ubVirtImageLocal" to "false" in "ops".

#toImage

#_closeChRoot

#_closeVBoxRaw

#_editQemu
#_editVBox

#_userChRoot
#_userQemu
#_userVBox

#_userDocker

#_dockerCommit
#_dockerLaunch
#_dockerAttach
#_dockerOn
#_dockerOff

_findInfrastructure_virtImage() {
	[[ "$ubVirtImageLocal" != "false" ]] && return 0
	
	[[ -e "$scriptLocal"/vm.img ]] && export ubVirtImageLocal="true" && return 0
	[[ -e "$scriptLocal"/vm.vdi ]] && export ubVirtImageLocal="true" && return 0
	[[ -e "$scriptLocal"/vmvdiraw.vmdi ]] && export ubVirtImageLocal="true" && return 0
	
	_checkSpecialLocks && export ubVirtImageLocal="true" && return 0
	
	_findInfrastructure_virtImage_script "$@"
}

# WARNING
#Overloading with "ops" is recommended.
_findInfrastructure_virtImage_script() {
	local infrastructureName=$(basename "$scriptAbsoluteFolder")
	
	local recursionExec
	local recursionExecList
	local currentRecursionExec
	
	recursionExecList+=("$scriptAbsoluteFolder"/../core/infrastructure/vm/"$infrastructureName"/ubiquitous_bash.sh)
	#recursionExecList+=("$scriptAbsoluteFolder"/../core/lab/"$infrastructureName"/ubiquitous_bash.sh)
	
	recursionExecList+=("$scriptAbsoluteFolder"/../../core/infrastructure/vm/"$infrastructureName"/ubiquitous_bash.sh)
	#recursionExecList+=("$scriptAbsoluteFolder"/../../core/lab/"$infrastructureName"/ubiquitous_bash.sh)
	
	recursionExecList+=("$scriptAbsoluteFolder"/../../../core/infrastructure/vm/"$infrastructureName"/ubiquitous_bash.sh)
	#recursionExecList+=("$scriptAbsoluteFolder"/../../../core/lab/"$infrastructureName"/ubiquitous_bash.sh)
	
	recursionExecList+=("$scriptAbsoluteFolder"/../../../../core/infrastructure/vm/"$infrastructureName"/ubiquitous_bash.sh)
	#recursionExecList+=("$scriptAbsoluteFolder"/../../../../core/lab/"$infrastructureName"/ubiquitous_bash.sh)
	
	recursionExecList+=("$scriptAbsoluteFolder"/../../../../../core/infrastructure/vm/"$infrastructureName"/ubiquitous_bash.sh)
	#recursionExecList+=("$scriptAbsoluteFolder"/../../../../../core/lab/"$infrastructureName"/ubiquitous_bash.sh)
	
	recursionExecList+=("$scriptAbsoluteFolder"/../../../../../../core/infrastructure/vm/"$infrastructureName"/ubiquitous_bash.sh)
	#recursionExecList+=("$scriptAbsoluteFolder"/../../../../../../core/lab/"$infrastructureName"/ubiquitous_bash.sh)
	
	recursionExecList+=("$scriptAbsoluteFolder"/../../../../../../../core/infrastructure/vm/"$infrastructureName"/ubiquitous_bash.sh)
	#recursionExecList+=("$scriptAbsoluteFolder"/../../../../../../../core/lab/"$infrastructureName"/ubiquitous_bash.sh)
	
	recursionExecList+=("$HOME"/core/infrastructure/vm/"$infrastructureName"/ubiquitous_bash.sh)
	
	recursionExecList+=("$HOME"/core/extra/infrastructure/vm/"$infrastructureName"/ubiquitous_bash.sh)
	
	local whichExeVM
	whichExeVM=nixexevm
	[[ "$virtOStype" == 'MSW'* ]] && whichExeVM=winexevm
	[[ "$virtOStype" == 'Windows'* ]] && whichExeVM=winexevm
	[[ "$vboxOStype" == 'Windows'* ]] && whichExeVM=winexevm
	
	
	recursionExecList+=("$scriptAbsoluteFolder"/../core/infrastructure/"$whichExeVM"/ubiquitous_bash.sh)
	recursionExecList+=("$scriptAbsoluteFolder"/../core/infrastructure/vm/"$whichExeVM"/ubiquitous_bash.sh)
	recursionExecList+=("$scriptAbsoluteFolder"/../../core/infrastructure/"$whichExeVM"/ubiquitous_bash.sh)
	recursionExecList+=("$scriptAbsoluteFolder"/../../core/infrastructure/vm/"$whichExeVM"/ubiquitous_bash.sh)
	recursionExecList+=("$scriptAbsoluteFolder"/../../../core/infrastructure/"$whichExeVM"/ubiquitous_bash.sh)
	recursionExecList+=("$scriptAbsoluteFolder"/../../../core/infrastructure/vm/"$whichExeVM"/ubiquitous_bash.sh)
	recursionExecList+=("$scriptAbsoluteFolder"/../../../../core/infrastructure/"$whichExeVM"/ubiquitous_bash.sh)
	recursionExecList+=("$scriptAbsoluteFolder"/../../../../core/infrastructure/vm/"$whichExeVM"/ubiquitous_bash.sh)
	recursionExecList+=("$scriptAbsoluteFolder"/../../../../../core/infrastructure/"$whichExeVM"/ubiquitous_bash.sh)
	recursionExecList+=("$scriptAbsoluteFolder"/../../../../../core/infrastructure/vm/"$whichExeVM"/ubiquitous_bash.sh)
	recursionExecList+=("$scriptAbsoluteFolder"/../../../../../../core/infrastructure/"$whichExeVM"/ubiquitous_bash.sh)
	recursionExecList+=("$scriptAbsoluteFolder"/../../../../../../core/infrastructure/vm/"$whichExeVM"/ubiquitous_bash.sh)
	recursionExecList+=("$scriptAbsoluteFolder"/../../../../../../../core/infrastructure/"$whichExeVM"/ubiquitous_bash.sh)
	recursionExecList+=("$scriptAbsoluteFolder"/../../../../../../../core/infrastructure/vm/"$whichExeVM"/ubiquitous_bash.sh)
	
	recursionExecList+=("$HOME"/core/infrastructure/"$whichExeVM"/ubiquitous_bash.sh)
	recursionExecList+=("$HOME"/core/extra/infrastructure/"$whichExeVM"/ubiquitous_bash.sh)
	
	recursionExecList+=("$HOME"/core/infrastructure/vm/"$whichExeVM"/ubiquitous_bash.sh)
	recursionExecList+=("$HOME"/core/extra/infrastructure/vm/"$whichExeVM"/ubiquitous_bash.sh)
	
	for currentRecursionExec in "${recursionExecList[@]}"
	do
		if _recursion_guard "$currentRecursionExec"
		then
			"$currentRecursionExec" "$@"
			return
		fi
	done
}


#Removes 'file://' often used by browsers.
_removeFilePrefix() {
	local translatedFileParam
	translatedFileParam=${1/#file:\/\/}
	
	_safeEcho_newline "$translatedFileParam"
}

#Translates back slash parameters (UNIX paths) to forward slash parameters (MSW paths).
_slashBackToForward() {
	local translatedFileParam
	translatedFileParam=${1//\//\\}
	
	_safeEcho_newline "$translatedFileParam"
}

_nixToMSW() {
	echo -e -n 'Z:'
	
	local localAbsoluteFirstParam
	localAbsoluteFirstParam=$(_getAbsoluteLocation "$1")
	
	local intermediateStepOne
	intermediateStepOne=_removeFilePrefix "$localAbsoluteFirstParam"
	
	_slashBackToForward "$intermediateStepOne"
}

#Determines whether test parameter is in the path of base parameter.
#"$1" == testParameter
#"$2" == baseParameter
_pathPartOf() {
	local testParameter
	testParameter="IAUjqyPF2s3gqjC0t1"
	local baseParameter
	baseParameter="JQRBqIoOVoDJuzc7k9"
	
	[[ -e "$1" ]] && testParameter=$(_getAbsoluteLocation "$1")
	[[ -e "$2" ]] && baseParameter=$(_getAbsoluteLocation "$2")
	
	[[ "$testParameter" != "$baseParameter"* ]] && return 1
	return 0
}

#Checks if file/directory exists on local filesystem, and meets other criteria. Intended to be called within the virtualization platform, through _checkBaseDirRemote . Often maintained merely for the sake of example.
_checkBaseDirLocal() {
	/bin/bash -c '[[ -e "'"$1"'" ]] && ! [[ -d "'"$1"'" ]] && [[ "'"$1"'" != "." ]] && [[ "'"$1"'" != ".." ]] && [[ "'"$1"'" != "./" ]] && [[ "'"$1"'" != "../" ]]'
}

_checkBaseDirRemote_app_localOnly() {
	false
}

_checkBaseDirRemote_app_remoteOnly() {
	[[ "$1" == "/bin/bash" ]] && return 0
}

# WARNING Strongly recommend not sharing root with guest, but this can be overridden by "ops".
_checkBaseDirRemote_common_localOnly() {
	[[ "$1" == "." ]] && return 0
	[[ "$1" == "./" ]] && return 0
	[[ "$1" == ".." ]] && return 0
	[[ "$1" == "../" ]] && return 0
	
	[[ "$1" == "/" ]] && return 0
	
	return 1
}

_checkBaseDirRemote_common_remoteOnly() {
	[[ "$1" == "/bin"* ]] && return 0
	[[ "$1" == "/lib"* ]] && return 0
	[[ "$1" == "/lib64"* ]] && return 0
	[[ "$1" == "/opt"* ]] && return 0
	[[ "$1" == "/usr"* ]] && return 0
	
	[[ "$1" == "/bin/bash" ]] && return 0
	
	#type "$1" > /dev/null 2>&1 && return 0
	
	#! [[ "$1" == "/"* ]] && return 0
	
	return 1
}

#Checks if file/directory exists on remote system. Overload this function with implementation specific to the container/virtualization solution in use (ie. docker run).
_checkBaseDirRemote() {
	_checkBaseDirRemote_common_localOnly "$1" && return 0
	_checkBaseDirRemote_common_remoteOnly "$1" && return 1
	
	_checkBaseDirRemote_app_localOnly "$1" && return 0
	_checkBaseDirRemote_app_remoteOnly "$1" && return 1
	
	[[ "$checkBaseDirRemote" == "" ]] && checkBaseDirRemote="false"
	"$checkBaseDirRemote" "$1" || return 1
	return 0
}

#Reports the highest-level directory containing all files in given parameter set.
#"$@" == parameters to search
#$checkBaseDirRemote == function to check if file/directory exists on remote system
_searchBaseDir() {
	local baseDir
	local newDir
	
	baseDir=""
	
	local processedArgs
	local currentArg
	local currentResult
	
	#Do not translate if exists on remote filesystem. Dummy check by default unless overloaded, by $checkBaseDirRemote value.
	#Intended to prevent "/bin/true" and similar from being translated, so execution of remote programs can be requested.
	for currentArg in "$@"
	do
		if _checkBaseDirRemote "$currentArg"
		then
			continue
		fi
		
		currentResult="$currentArg"
		processedArgs+=("$currentResult")
	done
	
	for currentArg in "${processedArgs[@]}"
	do
		
		if [[ ! -e "$currentArg" ]]
		then
			continue
		fi
		
		if [[ "$baseDir" == "" ]]
		then
			baseDir=$(_findDir "$currentArg")
		fi
		
		for subArg in "${processedArgs[@]}"
		do
			if [[ ! -e "$subArg" ]]
			then
				continue
			fi
			
			newDir=$(_findDir "$subArg")
			
			while [[ "$newDir" != "$baseDir"* ]]
			do
				baseDir=$(_findDir "$baseDir"/..)
				
				if [[ "$baseDir" == "/" ]]
				then
					break
				fi
			done
			
		done
		
		
		
		
	done
	
	_safeEcho_newline "$baseDir"
}

#Converts to relative path, if provided a file parameter.
#"$1" == parameter to search
#"$2" == sharedHostProjectDir
#"$3" == sharedGuestProjectDir (optional)
_localDir() {
	if _checkBaseDirRemote "$1"
	then
		_safeEcho_newline "$1"
		return
	fi
	
	if [[ ! -e "$2" ]]
	then
		_safeEcho_newline "$1"
		return
	fi
	
	if [[ ! -e "$1" ]] || ! _pathPartOf "$1" "$2"
	then
		_safeEcho_newline "$1"
		return
	fi
	
	[[ "$3" != "" ]] && _safeEcho "$3" && [[ "$3" != "/" ]] && _safeEcho "/"
	realpath -L -s --relative-to="$2" "$1"
	
}


#Takes a list of parameters, idenfities file parameters, finds a common path, and translates all parameters to that path. Essentially provides shared folder and file parameter translation for application virtualization solutions.
#Keep in mind this function has a relatively complex set of inputs and outputs, serving a critically wide variety of edgy use cases across platforms.
#"$@" == input parameters

#"$sharedHostProjectDir" == if already set, overrides the directory that will be shared, rarely used to share entire root
#"$sharedGuestProjectDir" == script default is /home/ubvrtusr/project, can be overridden, "X:" typical for MSW guests
#Setting sharedGuestProjectDir to a drive letter designation will also enable UNIX/MSW parameter translation mechanisms.

# export sharedHostProjectDir == common directory to bind mount
# export processedArgs == translated arguments to be used in place of "$@"

# WARNING Consider specified syntax for portability.
# _runExec "${processedArgs[@]}"
_virtUser() {
	export sharedHostProjectDir="$sharedHostProjectDir"
	export processedArgs
	
	[[ "$virtUserPWD" == "" ]] && export virtUserPWD="$outerPWD"
	
	if [[ -e /tmp/.X11-unix ]] && [[ "$DISPLAY" != "" ]] && type xauth > /dev/null 2>&1
	then
		export XSOCK=/tmp/.X11-unix
		export XAUTH=/tmp/.virtuser.xauth."$sessionid"
		touch $XAUTH
		xauth nlist $DISPLAY | sed -e 's/^..../ffff/' | xauth -f $XAUTH nmerge -
	fi
	
	if [[ "$sharedHostProjectDir" == "" ]]
	then
		sharedHostProjectDir=$(_searchBaseDir "$@" "$virtUserPWD")
		#sharedHostProjectDir="$safeTmp"/shared
		mkdir -p "$sharedHostProjectDir"
	fi
	
	export localPWD=$(_localDir "$virtUserPWD" "$sharedHostProjectDir" "$sharedGuestProjectDir")
	export virtUserPWD=
	
	#If $sharedGuestProjectDir matches MSW drive letter format, enable translation of other non-UNIX file parameter differences.
	local enableMSWtranslation
	enableMSWtranslation=false
	_safeEcho_newline "$sharedGuestProjectDir" | grep '^[[:alpha:]]\:\|^[[:alnum:]][[:alnum:]]\:\|^[[:alnum:]][[:alnum:]][[:alnum:]]\:' > /dev/null 2>&1 && enableMSWtranslation=true
	
	#http://stackoverflow.com/questions/15420790/create-array-in-loop-from-number-of-arguments
	#local processedArgs
	local currentArg
	local currentResult
	processedArgs=()
	for currentArg in "$@"
	do
		currentResult=$(_localDir "$currentArg" "$sharedHostProjectDir" "$sharedGuestProjectDir")
		[[ "$enableMSWtranslation" == "true" ]] && currentResult=$(_slashBackToForward "$currentResult")
		processedArgs+=("$currentResult")
	done
}

_stop_virtLocal() {
	[[ "$XAUTH" == "" ]] && return
	[[ ! -e "$XAUTH" ]] && return
	
	rm -f "$XAUTH" > /dev/null 2>&1
}

_test_virtLocal_X11() {
	_getDep xauth
}

# TODO: Expansion needed.
_vector_virtUser() {
	export sharedHostProjectDir=
	export sharedGuestProjectDir=/home/user/project
	_virtUser /tmp
	#_safeEcho_newline "${processedArgs[0]}"
	[[ "${processedArgs[0]}" != '/home/user/project/tmp' ]] && echo 'fail: _vector_virtUser' && _messageFAIL
	
	export sharedHostProjectDir=/
	export sharedGuestProjectDir='Z:'
	_virtUser /tmp
	#_safeEcho_newline "${processedArgs[0]}"
	[[ "${processedArgs[0]}" != 'Z:\tmp' ]] && echo 'fail: _vector_virtUser' && _messageFAIL
	
	export sharedHostProjectDir=/tmp
	export sharedGuestProjectDir='/home/user/project/tmp'
	_virtUser /tmp
	#_safeEcho_newline "${processedArgs[0]}"
	[[ "${processedArgs[0]}" != '/home/user/project/tmp/.' ]] && echo 'fail: _vector_virtUser' && _messageFAIL
	
	export virtUserPWD='/tmp'
	export sharedHostProjectDir=/tmp
	export sharedGuestProjectDir='/home/user/project/tmp'
	_virtUser /tmp
	#_safeEcho_newline "${processedArgs[0]}"
	#_safeEcho_newline "$localPWD"
	[[ "$localPWD" != '/home/user/project/tmp/.' ]] && echo 'fail: _vector_virtUser' && _messageFAIL
	
	export virtUserPWD='/tmp'
	export sharedHostProjectDir=/tmp
	export sharedGuestProjectDir='/home/user/project/tmp'
	_virtUser -e /tmp
	#_safeEcho_newline "${processedArgs[0]}"
	[[ "${processedArgs[0]}" != '-e' ]] && echo 'fail: _vector_virtUser' && _messageFAIL
	
	
	return 0
}






_test_abstractfs() {
	_getDep md5sum
}

_abstractfs() {
	#Nesting prohibited. Not fully tested.
	# WARNING: May cause infinite recursion symlinks.
	[[ "$abstractfs" != "" ]] && return 1
	
	_reset_abstractfs
	
	_prepare_abstract
	
	local abstractfs_command="$1"
	shift
	
	export virtUserPWD="$PWD"
	
	export abstractfs_puid=$(_uid)
	
	_base_abstractfs "$@"
	_name_abstractfs > /dev/null 2>&1
	[[ "$abstractfs_name" == "" ]] && return 1
	
	export abstractfs="$abstractfs_root"/"$abstractfs_name"
	
	_set_share_abstractfs
	_relink_abstractfs
	_virtUser "$@"
	
	cd "$localPWD"
	#cd "$abstractfs_base"
	#cd "$abstractfs"
	
	local commandExitStatus
	
	#_scope_terminal "${processedArgs[@]}"
	"$abstractfs_command" "${processedArgs[@]}"
	commandExitStatus=$?
	
	_set_share_abstractfs_reset
	_rmlink_abstractfs
	
	return "$commandExitStatus"
}

_reset_abstractfs() {
	export abstractfs=
	export abstractfs_base=
	export abstractfs_name=
	export abstractfs_puid=
	export abstractfs_projectafs=
}

_prohibit_rmlink_abstractfs() {
	#mkdir -p "$abstractfs_lock"/"$abstractfs_name"
	mkdir -p "$abstractfs_lock"/"$abstractfs_name"/"$abstractfs_puid"
}

_permit_rmlink_abstractfs() {
	#mkdir -p "$abstractfs_lock"/"$abstractfs_name"
	rmdir "$abstractfs_lock"/"$abstractfs_name"/"$abstractfs_puid" > /dev/null 2>&1
}

_wait_rmlink_abstractfs() {
	! [[ -e "$abstractfs_lock"/"$abstractfs_name"_rmlink ]] && return 0
	sleep 0.1
	
	! [[ -e "$abstractfs_lock"/"$abstractfs_name"_rmlink ]] && return 0
	sleep 0.3
	
	! [[ -e "$abstractfs_lock"/"$abstractfs_name"_rmlink ]] && return 0
	sleep 1
	
	! [[ -e "$abstractfs_lock"/"$abstractfs_name"_rmlink ]] && return 0
	sleep 3
	
	! [[ -e "$abstractfs_lock"/"$abstractfs_name"_rmlink ]] && return 0
	return 1
}

_rmlink_abstractfs() {
	mkdir -p "$abstractfs_lock"
	_permit_rmlink_abstractfs
	
	! _wait_rmlink_abstractfs && return 1
	
	echo > "$abstractfs_lock"/"$abstractfs_name"_rmlink
	
	rmdir "$abstractfs_lock"/"$abstractfs_name" >/dev/null 2>&1 && _rmlink "$abstractfs"
	rmdir "$abstractfs_root" >/dev/null 2>&1
	
	rm "$abstractfs_lock"/"$abstractfs_name"_rmlink
}

_relink_abstractfs() {
	! _wait_rmlink_abstractfs && return 1
	
	mkdir -p "$abstractfs_lock"
	_prohibit_rmlink_abstractfs
	
	! _wait_rmlink_abstractfs && return 1
	
	_relink "$sharedHostProjectDir" "$sharedGuestProjectDir"
}

#Precaution. Should not be a requirement in any production use.
_set_share_abstractfs_reset() {
	export sharedHostProjectDir="$sharedHostProjectDirDefault"
	export sharedGuestProjectDir="$sharedGuestProjectDirDefault"
}

# ATTENTION: Overload with "core.sh".
_set_share_abstractfs() {
	_set_share_abstractfs_reset
	
	export sharedHostProjectDir="$abstractfs_base"
	#export sharedHostProjectDir=$(_getAbsoluteFolder "$abstractfs_base")
	export sharedGuestProjectDir="$abstractfs"
	
	#Blank default. Resolves to lowest directory shared by "$PWD" and "$@" .
	#export sharedHostProjectDir="$sharedHostProjectDirDefault"
}

_describe_abstractfs() {
	local localFunctionEntryPWD
	localFunctionEntryPWD="$PWD"
	
	local testAbstractfsBase
	testAbstractfsBase="$abstractfs_base"
	[[ "$1" != "" ]] && testAbstractfsBase=$(_getAbsoluteLocation "$1")
	
	basename "$testAbstractfsBase"
	! cd "$testAbstractfsBase" >/dev/null 2>&1 && cd "$localFunctionEntryPWD" && return 1
	git rev-parse --abbrev-ref HEAD 2>/dev/null
	git remote show origin 2>/dev/null
	
	cd "$localFunctionEntryPWD"
}

_base_abstractfs() {
	export abstractfs_base=
	[[ "$@" != "" ]] && export abstractfs_base=$(_searchBaseDir "$@")
	[[ "$abstractfs_base" == "" ]] && export abstractfs_base=$(_searchBaseDir "$@" "$virtUserPWD")
}

_findProjectAFS_procedure() {
	[[ "$ub_findProjectAFS_maxheight" -gt "120" ]] && return 1
	let ub_findProjectAFS_maxheight="$ub_findProjectAFS_maxheight"+1
	export ub_findProjectAFS_maxheight
	
	if [[ -e "./project.afs" ]]
	then
		_getAbsoluteLocation "./project.afs"
		return 0
	fi
	
	[[ "$1" == "/" ]] && return 1
	
	! cd .. > /dev/null 2>&1 && return 1
	
	_findProjectAFS_procedure
}

#Recursively searches for directories containing "project.afs".
_findProjectAFS() {
	local localFunctionEntryPWD
	localFunctionEntryPWD="$PWD"
	
	cd "$1"
	
	_findProjectAFS_procedure
	
	cd "$localFunctionEntryPWD"
}

_projectAFS_here() {
	cat << CZXWXcRMTo8EmM8i4d
#!/usr/bin/env bash

export abstractfs_name="$abstractfs_name"
CZXWXcRMTo8EmM8i4d
}

_write_projectAFS() {
	local testAbstractfsBase
	testAbstractfsBase="$abstractfs_base"
	[[ "$1" != "" ]] && testAbstractfsBase=$(_getAbsoluteLocation "$1")
	
	( [[ "$nofs" == "true" ]] || [[ "$afs_nofs" == "true" ]] ) && return
	_projectAFS_here > "$testAbstractfsBase"/project.afs
	chmod u+x "$testAbstractfsBase"/project.afs
}

# DANGER: Mandatory strict directory 8.3 compliance for this variable! Long subdirectory/filenames permitted thereafter.
_default_name_abstractfs() {
	#If "$abstractfs_name" is not saved to file, a consistent, compressed, naming scheme, is required.
	if ( [[ "$nofs" == "true" ]] || [[ "$afs_nofs" == "true" ]] )
	then
		#echo $(basename "$abstractfs_base") | md5sum | head -c 8
		_describe_abstractfs "$@" | md5sum | head -c 8
		return
	fi
	
	cat /dev/urandom 2> /dev/null | base64 2> /dev/null | tr -dc 'a-z' 2> /dev/null | head -c "1" 2> /dev/null
	cat /dev/urandom 2> /dev/null | base64 2> /dev/null | tr -dc 'a-z0-9' 2> /dev/null | head -c "7" 2> /dev/null
}

#"$1" == "$abstractfs_base" || ""
_name_abstractfs() {
	export abstractfs_name=
	
	local testAbstractfsBase
	testAbstractfsBase="$abstractfs_base"
	[[ "$1" != "" ]] && testAbstractfsBase=$(_getAbsoluteLocation "$1")
	
	export abstractfs_projectafs=$(_findProjectAFS "$testAbstractfsBase")
	[[ "$abstractfs_projectafs" != "" ]] && [[ -e "$abstractfs_projectafs" ]] && . "$abstractfs_projectafs" --noexec
	
	if [[ "$abstractfs_name" == "" ]]
	then
		export abstractfs_name=$(_default_name_abstractfs "$testAbstractfsBase")
		if ( [[ "$nofs" == "true" ]] || [[ "$afs_nofs" == "true" ]] )
		then
			echo "$abstractfs_name"
			return
		fi
		_write_projectAFS "$testAbstractfsBase"
		export abstractfs_name=
	fi
	
	export abstractfs_projectafs=$(_findProjectAFS "$testAbstractfsBase")
	[[ "$abstractfs_projectafs" != "" ]] && [[ -e "$abstractfs_projectafs" ]] && . "$abstractfs_projectafs" --noexec
	
	( [[ "$nofs" == "true" ]] || [[ "$afs_nofs" == "true" ]] ) && [[ ! -e "$abstractfs_projectafs" ]] && return 1
	[[ "$abstractfs_name" == "" ]] && return 1
	
	echo "$abstractfs_name"
	return 0
}

_makeFakeHome_extra_layer0() {
	_relink "$1"/.bashrc "$2"/.bashrc
	_relink "$1"/.ubcore "$2"/.ubcore
	
	_relink "$1"/.Xauthority "$2"/.Xauthority
	
	_relink "$1"/.ssh "$2"/.ssh
	_relink "$1"/.gitconfig "$2"/.gitconfig
	
	mkdir -p "$2"/.config
}

_makeFakeHome_extra_layer1() {
	true
}

#"$1" == sourceHome
#"$2" == destinationHome
_makeFakeHome() {
	[[ "$1" == "" ]] && return 1
	! [[ -d "$1" ]] && return 1
	
	[[ "$2" == "" ]] && return 1
	[[ "$2" == "/home/""$USER" ]] && return 1
	! [[ -d "$2" ]] && return 1
	
	_relink "$1" "$2"/realHome
	
	_relink "$1"/Downloads "$2"/Downloads
	
	_relink "$1"/Desktop "$2"/Desktop
	_relink "$1"/Documents "$2"/Documents
	_relink "$1"/Music "$2"/Music
	_relink "$1"/Pictures "$2"/Pictures
	_relink "$1"/Public "$2"/Public
	_relink "$1"/Templates "$2"/Templates
	_relink "$1"/Videos "$2"/Videos
	
	_relink "$1"/bin "$2"/bin
	
	_relink "$1"/core "$2"/core
	_relink "$1"/project "$2"/project
	_relink "$1"/projects "$2"/projects
	
	
	
	_makeFakeHome_extra_layer0 "$@"
	_makeFakeHome_extra_layer1 "$@"
}

_unmakeFakeHome_extra_layer0() {
	_rmlink "$1"/.bashrc
	_rmlink "$1"/.ubcore
	
	_rmlink "$1"/.Xauthority
	
	_rmlink "$1"/.ssh
	_rmlink "$1"/.gitconfig
	
	rmdir "$1"/.config
}

_unmakeFakeHome_extra_layer1() {
	true
}

#"$1" == destinationHome
_unmakeFakeHome() {
	[[ "$1" == "" ]] && return 1
	[[ "$1" == "/home/""$USER" ]] && return 1
	! [[ -d "$1" ]] && return 1
	
	_rmlink "$1"/realHome
	
	_rmlink "$1"/Downloads
	
	_rmlink "$1"/Desktop
	_rmlink "$1"/Documents
	_rmlink "$1"/Music
	_rmlink "$1"/Pictures
	_rmlink "$1"/Public
	_rmlink "$1"/Templates
	_rmlink "$1"/Videos
	
	_rmlink "$1"/bin
	
	_rmlink "$1"/core
	_rmlink "$1"/project
	_rmlink "$1"/projects
	
	
	
	_unmakeFakeHome_extra_layer0 "$@"
	_unmakeFakeHome_extra_layer1 "$@"
}

_test_fakehome() {
	_getDep mount
	_getDep mountpoint
	
	_getDep rsync
}

#Example. Run similar code under "core.sh" before calling "_fakeHome", "_install_fakeHome", or similar, to set a specific type/location for fakeHome environment - global, instanced, or otherwise.
_arbitrary_fakeHome_app() {
	export actualFakeHome="$instancedFakeHome"
	#export actualFakeHome="$shortFakeHome"
	
	#export actualFakeHome="$globalFakeHome"
	#export actualFakeHome=""$arbitraryFakeHome"/arbitrary"
}

#"$1" == lib source path (eg. "$scriptLib"/app/.app)
#"$2" == home destination path (eg. ".app")
# WARNING: Locking mechanism not intended to be relied on.
# WARNING: Return status success may not reflect successful link/copy.
_link_fakeHome() {
	mkdir -p "$1" > /dev/null 2>&1
	mkdir -p "$actualFakeHome" > /dev/null 2>&1
	mkdir -p "$globalFakeHome" > /dev/null 2>&1
	
	#If globalFakeHome symlinks are obsolete, subsequent _instance_internal operation may overwrite valid links with them. See _install_fakeHome .
	rmdir "$globalFakeHome"/"$2" > /dev/null 2>&1
	_relink "$1" "$globalFakeHome"/"$2"
	
	if [[ "$actualFakeHome" == "$globalFakeHome" ]] || [[ "$fakeHomeEditLib" == "true" ]]
	then
		rmdir "$actualFakeHome"/"$2" > /dev/null 2>&1
		_relink "$1" "$actualFakeHome"/"$2"
		return 0
	fi
	
	#Actual files/directories will not be overwritten by symlinks when "$globalFakeHome" is copied to "$actualFakeHome". Remainder of this function dedicated to creating copies, before and instead of, symlinks.
	
	#rmdir "$actualFakeHome"/"$2" > /dev/null 2>&1
	_rmlink "$actualFakeHome"/"$2"
	
	#Waits if copy is in progress, delaying program launch.
	local lockWaitTimer
	for (( lockWaitTimer = 0 ; lockWaitTimer <= 90 ; lockWaitTimer++ )); do
		! [[ -e "$actualFakeHome"/"$2".lck ]] && break
		sleep 0.3
	done
	
	#Checks if copy has already been made.
	[[ -e "$actualFakeHome"/"$2" ]] && return 0
	
	mkdir -p "$actualFakeHome"/"$2"
	
	#Copy file.
	if ! [[ -d "$1" ]] && [[ -e "$1" ]]
	then
		rmdir "$actualFakeHome"/"$2" > /dev/null 2>&1
		
		echo > "$actualFakeHome"/"$2".lck
		cp "$1" "$actualFakeHome"/"$2"
		rm "$actualFakeHome"/"$2".lck
		return 0
	fi
	
	#Copy directory.
	echo > "$actualFakeHome"/"$2".lck
	_instance_internal "$1"/. "$actualFakeHome"/"$2"/
	rm "$actualFakeHome"/"$2".lck
	return 0
}

#Example. Override with "core.sh". Allows specific application configuration directories to reside outside of globalFakeHome, for organization, testing, and distribution.
_install_fakeHome_app() {
	#_link_fakeHome "$scriptLib"/app/.app ".app"
	
	true
}

#actualFakeHome
_install_fakeHome() {
	_install_fakeHome_app
	
	#Asterisk used where multiple global home folders are needed, following convention "$scriptLocal"/h_* . Used by webClient for _firefox_esr .
	[[ "$actualFakeHome" == "$globalFakeHome"* ]] && return 0
	
	#Any globalFakeHome links created by "_link_fakeHome" are not to overwrite copies made to instancedFakeHome directories. Related errors emitted by "rsync" are normal, and therefore, silenced.
	_instance_internal "$globalFakeHome"/. "$actualFakeHome"/ > /dev/null 2>&1
}

#Run before _fakeHome to use a ramdisk as home directory. Wrap within "_wantSudo" and ">/dev/null 2>&1" to use optionally. Especially helpful to limit SSD wear when dealing with moderately large (ie. ~2GB) fakeHome environments which must be instanced.
_mountRAM_fakeHome() {
	_mustGetSudo
	mkdir -p "$actualFakeHome"
	sudo -n mount -t ramfs ramfs "$actualFakeHome"
	sudo -n chown "$USER":"$USER" "$actualFakeHome"
	! mountpoint "$actualFakeHome" > /dev/null 2>&1 && _stop 1
	return 0
}

_umountRAM_fakeHome() {
	mkdir -p "$actualFakeHome"
	sudo -n umount "$actualFakeHome"
	mountpoint "$actualFakeHome" > /dev/null 2>&1 && _stop 1
	return 0
}

_begin_fakeHome() {
	#Recursive fakeHome prohibited. Instead, start new script session, with new sessionid, and keepFakeHome=false. Do not workaround without a clear understanding why this may endanger your application.
	[[ "$setFakeHome" == "true" ]] && return 1
	#_resetFakeHomeEnv_nokeep
	
	[[ "$realHome" == "" ]] && export realHome="$HOME"
	
	export HOME="$actualFakeHome"
	export setFakeHome=true
	
	_prepareFakeHome > /dev/null 2>&1
	
	_install_fakeHome
	
	_makeFakeHome "$realHome" "$actualFakeHome"
	
	export fakeHomeEditLib="false"
	
	export realScriptAbsoluteLocation="$scriptAbsoluteLocation"
	export realScriptAbsoluteFolder="$scriptAbsoluteFolder"
	export realSessionID="$sessionid"
}

#actualFakeHome
	#default: "$instancedFakeHome"
	#"$globalFakeHome" || "$instancedFakeHome" || "$shortFakeHome" || "$arbitraryFakeHome"/arbitrary
#keepFakeHome
	#default: true
	#"true" || "false"
_fakeHome() {
	_begin_fakeHome "$@"
	local fakeHomeExitStatus
	
	if ! _safeEcho_newline "$_JAVA_OPTIONS" | grep "$HOME" > /dev/null 2>&1
	then
		export _JAVA_OPTIONS=-Duser.home="$HOME"' '"$_JAVA_OPTIONS"
	fi
	
	env -i DISPLAY="$DISPLAY" XAUTH="$XAUTH" XAUTHORITY="$XAUTHORITY" XSOCK="$XSOCK" realHome="$realHome" keepFakeHome="$keepFakeHome" HOME="$HOME" setFakeHome="$setFakeHome" TERM="${TERM}" SHELL="${SHELL}" PATH="${PATH}" _JAVA_OPTIONS=${_JAVA_OPTIONS}scriptAbsoluteLocation="$scriptAbsoluteLocation" sessionid="$sessionid" scriptAbsoluteFolder="$scriptAbsoluteFolder" realSessionID="$realSessionID" realScriptAbsoluteLocation="$realScriptAbsoluteLocation" realScriptAbsoluteFolder="$realScriptAbsoluteFolder" dbus-run-session "$@"
	#env -i DISPLAY="$DISPLAY" XAUTH="$XAUTH" XAUTHORITY="$XAUTHORITY" XSOCK="$XSOCK" realHome="$realHome" keepFakeHome="$keepFakeHome" HOME="$HOME" setFakeHome="$setFakeHome" TERM="${TERM}" SHELL="${SHELL}" PATH="${PATH}" _JAVA_OPTIONS=${_JAVA_OPTIONS}scriptAbsoluteLocation="$scriptAbsoluteLocation" scriptAbsoluteFolder="$scriptAbsoluteFolder" dbus-run-session "$@"
	#dbus-run-session "$@"
	#"$@"
	#. "$@"
	fakeHomeExitStatus=$?
	
	#_unmakeFakeHome > /dev/null 2>&1
	
	_resetFakeHomeEnv_nokeep
	
	return "$fakeHomeExitStatus"
}

#Do NOT keep parent session under fakeHome environment. Do NOT regain parent session if "~/.ubcore/.ubcorerc" is imported (typically upon shell launch).
_fakeHome_specific() {
	_begin_fakeHome "$@"
	local fakeHomeExitStatus
	
	if ! _safeEcho_newline "$_JAVA_OPTIONS" | grep "$HOME" > /dev/null 2>&1
	then
		export _JAVA_OPTIONS=-Duser.home="$HOME"' '"$_JAVA_OPTIONS"
	fi
	
	#env -i DISPLAY="$DISPLAY" XAUTH="$XAUTH" XAUTHORITY="$XAUTHORITY" XSOCK="$XSOCK" realHome="$realHome" keepFakeHome="$keepFakeHome" HOME="$HOME" setFakeHome="$setFakeHome" TERM="${TERM}" SHELL="${SHELL}" PATH="${PATH}" _JAVA_OPTIONS=${_JAVA_OPTIONS}scriptAbsoluteLocation="$scriptAbsoluteLocation" scriptAbsoluteFolder="$scriptAbsoluteFolder" realScriptAbsoluteLocation="$realScriptAbsoluteLocation" realScriptAbsoluteFolder="$realScriptAbsoluteFolder" dbus-run-session "$@"
	env -i DISPLAY="$DISPLAY" XAUTH="$XAUTH" XAUTHORITY="$XAUTHORITY" XSOCK="$XSOCK" realHome="$realHome" keepFakeHome="$keepFakeHome" HOME="$HOME" setFakeHome="$setFakeHome" TERM="${TERM}" SHELL="${SHELL}" PATH="${PATH}" _JAVA_OPTIONS=${_JAVA_OPTIONS}dbus-run-session "$@"
	#dbus-run-session "$@"
	#"$@"
	#. "$@"
	fakeHomeExitStatus=$?
	
	#_unmakeFakeHome > /dev/null 2>&1
	
	_resetFakeHomeEnv_nokeep
	
	return "$fakeHomeExitStatus"
}

#No workarounds, run in current shell.
# WARNING: Not recommended. No production use. Do not launch GUI applications.
_fakeHome_embedded() {
	_begin_fakeHome "$@"
	local fakeHomeExitStatus
	
	if ! _safeEcho_newline "$_JAVA_OPTIONS" | grep "$HOME" > /dev/null 2>&1
	then
		export _JAVA_OPTIONS=-Duser.home="$HOME"' '"$_JAVA_OPTIONS"
	fi
	
	#env -i DISPLAY="$DISPLAY" XAUTH="$XAUTH" XAUTHORITY="$XAUTHORITY" XSOCK="$XSOCK" realHome="$realHome" keepFakeHome="$keepFakeHome" HOME="$HOME" setFakeHome="$setFakeHome" TERM="${TERM}" SHELL="${SHELL}" PATH="${PATH}" _JAVA_OPTIONS=${_JAVA_OPTIONS}scriptAbsoluteLocation="$scriptAbsoluteLocation" scriptAbsoluteFolder="$scriptAbsoluteFolder" realScriptAbsoluteLocation="$realScriptAbsoluteLocation" realScriptAbsoluteFolder="$realScriptAbsoluteFolder" dbus-run-session "$@"
	#env -i DISPLAY="$DISPLAY" XAUTH="$XAUTH" XAUTHORITY="$XAUTHORITY" XSOCK="$XSOCK" realHome="$realHome" keepFakeHome="$keepFakeHome" HOME="$HOME" setFakeHome="$setFakeHome" TERM="${TERM}" SHELL="${SHELL}" PATH="${PATH}" _JAVA_OPTIONS=${_JAVA_OPTIONS}scriptAbsoluteLocation="$scriptAbsoluteLocation" scriptAbsoluteFolder="$scriptAbsoluteFolder" dbus-run-session "$@"
	#dbus-run-session "$@"
	#"$@"
	. "$@"
	fakeHomeExitStatus=$?
	
	#_unmakeFakeHome > /dev/null 2>&1
	
	_resetFakeHomeEnv_nokeep
	
	return "$fakeHomeExitStatus"
}

_fakeHome_() {
	_fakeHome_embedded "$@"
}





_userFakeHome_procedure() {
	export actualFakeHome="$instancedFakeHome"
	export fakeHomeEditLib="false"
	_fakeHome "$@"
}

_userFakeHome_sequence() {
	_start
	
	_userFakeHome_procedure "$@"
	
	_stop $?
}

_userFakeHome() {
	"$scriptAbsoluteLocation" _userFakeHome_sequence "$@"
}

_editFakeHome_procedure() {
	export actualFakeHome="$globalFakeHome"
	export fakeHomeEditLib="false"
	_fakeHome "$@"
}

_editFakeHome_sequence() {
	_start
	
	_editFakeHome_procedure "$@"
	
	_stop $?
}

_editFakeHome() {
	"$scriptAbsoluteLocation" _editFakeHome_sequence "$@"
}

_userShortHome_procedure() {
	export actualFakeHome="$shortFakeHome"
	export fakeHomeEditLib="false"
	_fakeHome "$@"
}

_userShortHome_sequence() {
	_start
	
	_userShortHome_procedure "$@"
	
	_stop $?
}

_userShortHome() {
	"$scriptAbsoluteLocation" _userShortHome_sequence "$@"
}

_editShortHome_procedure() {
	export actualFakeHome="$shortFakeHome"
	export fakeHomeEditLib="true"
	_fakeHome "$@"
}

_editShortHome_sequence() {
	_start
	
	_editShortHome_procedure "$@"
	
	_stop $?
}

# WARNING: Only allows persistent modifications to directories which have been linked by "_link_fakeHome" or similar.
_editShortHome() {
	"$scriptAbsoluteLocation" _editShortHome_sequence "$@"
}

_shortHome() {
	_userShortHome "$@"
}

_memFakeHome_procedure() {
	export actualFakeHome="$instancedFakeHome"
	export fakeHomeEditLib="false"
	
	_mountRAM_fakeHome
	
	local fakeHomeExitStatus
	
	_fakeHome "$@"
	fakeHomeExitStatus=$?
	
	_umountRAM_fakeHome
	
	return "$fakeHomeExitStatus"
}

_memFakeHome_sequence() {
	_start
	
	_memFakeHome_procedure "$@"
	
	_stop $?
}

_memFakeHome() {
	"$scriptAbsoluteLocation" _memFakeHome_sequence "$@"
}

_resetFakeHomeEnv_extra() {
	true
}

_resetFakeHomeEnv_nokeep() {
	! [[ "$setFakeHome" == "true" ]] && return 0
	export setFakeHome="false"
	
	export HOME="$realHome"
	
	#export realHome=""
	
	_resetFakeHomeEnv_extra
}

_resetFakeHomeEnv() {
	#[[ "$keepFakeHome" == "true" ]] && return 0
	[[ "$keepFakeHome" != "false" ]] && return 0
	
	_resetFakeHomeEnv_nokeep
} 

_test_image() {
	_mustGetSudo
	
	_getDep losetup
	#_getDep partprobe
}

_loopImage_sequence() {
	_mustGetSudo
	
	_start
	
	mkdir -p "$globalVirtFS"
	
	[[ -e "$scriptLocal"/imagedev ]] && _stop 1
	
	local imagefilename
	#[[ -e "$scriptLocal"/vm-x64.img ]] && imagefilename="$scriptLocal"/vm-x64.img
	[[ -e "$scriptLocal"/vm.img ]] && imagefilename="$scriptLocal"/vm.img
	
	sudo -n losetup -f -P --show "$imagefilename" > "$safeTmp"/imagedev 2> /dev/null || _stop 1
	sudo -n partprobe > /dev/null 2>&1
	
	cp -n "$safeTmp"/imagedev "$scriptLocal"/imagedev > /dev/null 2>&1 || _stop 1
	
	_stop 0
}

_loopImage() {
	"$scriptAbsoluteLocation" _loopImage_sequence
}

_mountImageFS_sequence() {
	_mustGetSudo
	
	_start
	
	mkdir -p "$globalVirtFS"
	
	"$scriptAbsoluteLocation" _checkForMounts "$globalVirtFS" && _stop 1
	
	local imagedev
	imagedev=$(cat "$scriptLocal"/imagedev)
	
	local imagepart
	#imagepart="$imagedev"p2
	imagepart="$imagedev"p1
	
	local loopdevfs
	loopdevfs=$(eval $(sudo -n blkid "$imagepart" | awk ' { print $3 } '); echo $TYPE)
	
	! [[ "$loopdevfs" == "ext4" ]] && _stop 1
	
	sudo -n mount "$imagepart" "$globalVirtFS" || _stop 1
	
	mountpoint "$globalVirtFS" > /dev/null 2>&1 || _stop 1
	
	_stop 0
}

_mountImageFS() {
	"$scriptAbsoluteLocation" _mountImageFS_sequence
}

_mountImage() {
	"$scriptAbsoluteLocation" _loopImage_sequence 
	"$scriptAbsoluteLocation" _mountImageFS_sequence
}

_umountLoop() {
	_mustGetSudo || return 1
	
	local imagedev
	imagedev=$(cat "$scriptLocal"/imagedev)
	
	sudo -n losetup -d "$imagedev" > /dev/null 2>&1 || return 1
	sudo -n partprobe > /dev/null 2>&1
	
	rm -f "$scriptLocal"/imagedev || return 1
	
	rm -f "$lock_quicktmp" > /dev/null 2>&1
	
	return 0
}

# TODO Duplicates some code from _umountLoop. Test, and remove.
_umountImage() {
	_mustGetSudo || return 1
	
	sudo -n umount "$globalVirtFS" > /dev/null 2>&1
	
	#Uniquely, it is desirable to allow unmounting to proceed a little further if the filesystem was not mounted to begin with. Enables manual intervention.
	_readyImage "$globalVirtFS" && return 1
	
	local imagedev
	imagedev=$(cat "$scriptLocal"/imagedev)
	
	sudo -n losetup -d "$imagedev" > /dev/null 2>&1 || return 1
	sudo -n partprobe > /dev/null 2>&1
	
	rm -f "$scriptLocal"/imagedev || return 1
	
	rm -f "$lock_quicktmp" > /dev/null 2>&1
	
	return 0
}

_waitLoop_opening() {
	[[ -e "$scriptLocal"/imagedev ]] && return 0
	sleep 0.1
	[[ -e "$scriptLocal"/imagedev ]] && return 0
	sleep 0.3
	for iteration in `seq 1 45`;
	do
		[[ -e "$scriptLocal"/imagedev ]] && return 0
		sleep 1
	done
	
	return 1
}

_waitImage_opening() {
	_readyImage "$globalVirtFS" && return 0
	sleep 1
	_readyImage "$globalVirtFS" && return 0
	sleep 3
	_readyImage "$globalVirtFS" && return 0
	sleep 9
	_readyImage "$globalVirtFS" && return 0
	sleep 27
	_readyImage "$globalVirtFS" && return 0
	sleep 81
	_readyImage "$globalVirtFS" && return 0
	
	return 1
}

_waitLoop_closing() {
	! [[ -e "$scriptLocal"/imagedev ]] && return 0
	sleep 0.1
	! [[ -e "$scriptLocal"/imagedev ]] && return 0
	sleep 0.3
	for iteration in `seq 1 45`;
	do
		! [[ -e "$scriptLocal"/imagedev ]] && return 0
		sleep 1
	done
	
	return 1
}

_waitImage_closing() {
	_readyImage "$globalVirtFS" || return 0
	sleep 1
	_readyImage "$globalVirtFS" || return 0
	sleep 3
	_readyImage "$globalVirtFS" || return 0
	sleep 9
	_readyImage "$globalVirtFS" || return 0
	sleep 27
	_readyImage "$globalVirtFS" || return 0
	sleep 81
	_readyImage "$globalVirtFS" || return 0
	
	return 1
}

_readyImage() {
	local absolute1
	absolute1=$(_getAbsoluteLocation "$1")
	
	mountpoint "$absolute1" > /dev/null 2>&1 || return 1
	
	return 0
}

_openImage() {
	local returnStatus
	
	export specialLock="$lock_open_image"
	
	_open _waitImage_opening _mountImage
	returnStatus="$?"
	
	export specialLock=""
	
	return "$returnStatus"
}

_closeImage() {
	local returnStatus
	
	export specialLock="$lock_open_image"
	
	if [[ "$1" == "--force" ]]
	then
		_close --force _waitImage_closing _umountImage
		returnStatus="$?"
		
		export specialLock=""
		
		return "$returnStatus"
	fi
	
	_close _waitImage_closing _umountImage
	returnStatus="$?"
	
	export specialLock=""
	
	return "$returnStatus"
}

_openLoop() {
	local returnStatus
	
	export specialLock="$lock_loop_image"
	
	_open _waitLoop_opening _loopImage
	returnStatus="$?"
	
	export specialLock=""
	
	return "$returnStatus"
}

_closeLoop() {
	local returnStatus
	
	export specialLock="$lock_loop_image"
	
	if [[ "$1" == "--force" ]]
	then
		_close --force _waitLoop_closing _umountLoop
		returnStatus="$?"
		
		export specialLock=""
		
		return "$returnStatus"
	fi
	
	_close _waitLoop_closing _umountLoop
	returnStatus="$?"
	
	export specialLock=""
	
	return "$returnStatus"
}

_testCreateFS() {
	_mustGetSudo
	
	_getDep mkfs
	_getDep mkfs.ext4
}

_testCreatePartition() {
	_mustGetSudo
	
	_getDep parted
	#_getDep partprobe
}

_createRawImage_sequence() {
	_start
	
	export vmImageFile="$scriptLocal"/vm.img
	
	[[ "$1" != "" ]] && export vmImageFile="$1"
	
	local createRawImageSize
	createRawImageSize=7636
	[[ "$vmSize" != "" ]] && createRawImageSize="$vmSize"
	
	[[ "$vmImageFile" == "" ]] && _stop 1
	[[ -e "$vmImageFile" ]] && _stop 1
	
	dd if=/dev/zero of="$vmImageFile" bs=1M count="$createRawImageSize" > /dev/null 2>&1
	
	_stop
}

_createRawImage() {
	
	"$scriptAbsoluteLocation" _createRawImage_sequence "$@"
	
}

_createPartition() {
	_mustGetSudo
	
	sudo -n parted --script "$scriptLocal"/vm.img mklabel msdos
	sudo -n partprobe > /dev/null 2>&1
	sudo -n parted "$scriptLocal"/vm.img --script -- mkpart primary 0% 100%
	sudo -n partprobe > /dev/null 2>&1
}


_createFS_sequence() {
	_mustGetSudo
	
	_start
	
	mkdir -p "$globalVirtFS"
	
	"$scriptAbsoluteLocation" _checkForMounts "$globalVirtFS" && _stop 1
	
	local imagedev
	imagedev=$(cat "$scriptLocal"/imagedev)
	
	local imagepart
	#imagepart="$imagedev"p2
	imagepart="$imagedev"p1
	
	local loopdevfs
	loopdevfs=$(eval $(sudo -n blkid "$imagepart" | awk ' { print $3 } '); echo $TYPE)
	[[ "$loopdevfs" == "ext4" ]] && _stop 1
	sudo -n mkfs.ext4 "$imagepart" > /dev/null 2>&1 || _stop 1
	
	_stop 0
}

_createFS_shell() {
	"$scriptAbsoluteLocation" _loopImage_sequence || return 1
	"$scriptAbsoluteLocation" _createFS_sequence || return 1
	"$scriptAbsoluteLocation" _umountImage || return 1
	return 0
}

_createFS() {
	local returnCode
	_open true _createFS_shell
	returnCode="$?"
	_close true true
	
	return "$returnCode"
}





_here_bootdisc_statup_xdg() {
cat << 'CZXWXcRMTo8EmM8i4d'
[Desktop Entry]
Comment=
Exec=/media/bootdisc/cmd.sh
GenericName=
Icon=exec
MimeType=
Name=
Path=
StartupNotify=false
Terminal=false
TerminalOptions=
Type=Application
CZXWXcRMTo8EmM8i4d
}

_here_bootdisc_rootnix() {
cat << 'CZXWXcRMTo8EmM8i4d'
#!/bin/bash

if [[ "$0" != "/media/bootdisc/rootnix.sh" ]] && [[ -e "/media/bootdisc" ]]
then
	for iteration in `seq 1 25`;
	do
		! /bin/mountpoint /media/bootdisc > /dev/null 2>&1 && ! [[ -e "/media/bootdisc/rootnix.sh" ]] && sleep 6
	done
	sleep 0.1
	/media/bootdisc/rootnix.sh "$@"
	exit
fi

#Equivalent "fstab" entries for reference. Not used due to conflict for mountpoint, as well as lack of standard mounting options in vboxsf driver.
#//10.0.2.4/qemu	/home/user/.pqm cifs	guest,_netdev,uid=user,user,nofail,exec		0 0
#appFolder		/home/user/.pvb	vboxsf	uid=user,_netdev				0 0

_mountGuestShareNIX() {
	! /bin/mountpoint /home/user/project > /dev/null 2>&1 && /bin/mount -t vboxsf -o uid=user,_netdev appFolder /home/user/project 2>&1
	! /bin/mountpoint /home/user/Downloads > /dev/null 2>&1 && /bin/mount -t vboxsf -o uid=user,_netdev Downloads /home/user/Downloads 2>&1
	
	! /bin/mountpoint /home/user/project > /dev/null 2>&1 && /bin/mount -t cifs -o guest,_netdev,uid=user,user,nofail,exec '//10.0.2.4/qemu' /home/user/project > /dev/null 2>&1
	
}

#http://stackoverflow.com/questions/687948/timeout-a-command-in-bash-without-unnecessary-delay
_timeout() { ( set +b; sleep "$1" & "${@:2}" & wait -n; r=$?; kill -9 `jobs -p`; exit $r; ) }

_uid() {
	local uidLength
	[[ -z "$1" ]] && uidLength=18 || uidLength="$1"
	
	cat /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c "$uidLength"
}

export sessionid=$(_uid)
[[ -d /tmp ]] && export bootTmp=/tmp		#Typical BSD
[[ -d /dev/shm ]] && export bootTmp=/dev/shm	#Typical Linux

echo "rootnix" > "$bootTmp"/"$sessionid".rnx

#/bin/mkdir -p /home/user/.pqm
#/bin/mkdir -p /home/user/.pvb

/bin/mkdir -p /home/user/Downloads
! /bin/mountpoint /home/user/Downloads && /bin/chown user:user /home/user/Downloads

/bin/mkdir -p /home/user/project
! /bin/mountpoint /home/user/project && /bin/chown user:user /home/user/project

! /bin/mountpoint /home/user/project > /dev/null 2>&1 && sleep 0.1 && _mountGuestShareNIX
! /bin/mountpoint /home/user/project > /dev/null 2>&1 && sleep 0.3 && _mountGuestShareNIX
! /bin/mountpoint /home/user/project > /dev/null 2>&1 && sleep 1 && _mountGuestShareNIX
! /bin/mountpoint /home/user/project > /dev/null 2>&1 && sleep 3 && _mountGuestShareNIX

for iteration in `seq 1 15`;
do
	! /bin/mountpoint /home/user/project > /dev/null 2>&1 && sleep 6 && _mountGuestShareNIX
done

! /bin/mountpoint /home/user/project > /dev/null 2>&1 && sleep 9 && _mountGuestShareNIX
! /bin/mountpoint /home/user/project > /dev/null 2>&1 && sleep 18 && _mountGuestShareNIX
! /bin/mountpoint /home/user/project > /dev/null 2>&1 && sleep 27 && _mountGuestShareNIX

CZXWXcRMTo8EmM8i4d
}

_here_bootdisc_startupbat() {
cat << 'CZXWXcRMTo8EmM8i4d'
REM CALL A:\uk4uPhB6.bat
REM CALL B:\uk4uPhB6.bat
CALL D:\uk4uPhB6.bat
CALL E:\uk4uPhB6.bat
CALL F:\uk4uPhB6.bat
CALL G:\uk4uPhB6.bat
CALL H:\uk4uPhB6.bat
CALL Y:\shell.bat
CZXWXcRMTo8EmM8i4d
}

_here_bootdisc_shellbat() {
cat << 'CZXWXcRMTo8EmM8i4d'
CALL Y:\loader.bat
CALL Y:\application.bat
CZXWXcRMTo8EmM8i4d
}

#No production use.
_here_bootdisc_loaderZbat() {
cat << 'CZXWXcRMTo8EmM8i4d'
net use z: /delete

:checkMount

net use /USER:guest z: \\VBOXSVR\root ""

ping -n 2 127.0.0.1 > nul
IF NOT EXIST "Z:\" GOTO checkMount
CZXWXcRMTo8EmM8i4d
}

_here_bootdisc_loaderXbat() {
cat << 'CZXWXcRMTo8EmM8i4d'
net use x: /delete

:checkMount

net use /USER:guest x: \\VBOXSVR\appFolder ""
net use /USER:guest x: \\10.0.2.4\qemu ""

ping -n 2 127.0.0.1 > nul
IF NOT EXIST "X:\" GOTO checkMount
CZXWXcRMTo8EmM8i4d
}

_testVirtBootdisc() {
	if ! type mkisofs > /dev/null 2>&1 && ! type genisoimage > /dev/null 2>&1
	then
		echo 'need mkisofs or genisoimage'
		_stop 1
	fi
}

_prepareBootdisc() {
	mkdir -p "$hostToGuestFiles" > /dev/null 2>&1 || return 1
	mkdir -p "$hostToGuestDir" > /dev/null 2>&1 || return 1
	return 0
}

_mkisofs() {
	if type mkisofs > /dev/null 2>&1
	then
		mkisofs "$@"
		return $?
	fi
	
	if type genisoimage > /dev/null 2>&1
	then
		genisoimage "$@"
		return $?
	fi
}

_writeBootdisc() {
	_mkisofs -V "$ubiquitiousBashID" -volset "$ubiquitiousBashID" -sysid "$ubiquitiousBashID" -R -uid 0 -gid 0 -dir-mode 0555 -file-mode 0555 -new-dir-mode 0555 -J -hfs -o "$hostToGuestISO" "$hostToGuestFiles"
}

_setShareMSW_app() {
	export sharedHostProjectDir="$sharedHostProjectDirDefault"
	export sharedGuestProjectDir="$sharedGuestProjectDirDefault"
	
	export sharedGuestProjectDir="X:"
}

#No production use. Not recommended.
_setShareMSW_root() {
	export sharedHostProjectDir="$sharedHostProjectDirDefault"
	export sharedGuestProjectDir="$sharedGuestProjectDirDefault"
	
	export sharedHostProjectDir=/
	export sharedGuestProjectDir="Z:"
}

_setShareMSW() {
	[[ "$flagShareApp" ]] && _setShareMSW_app && return
	[[ "$flagShareApp" ]] && _setShareMSW_root && return
	return 1
}

#Consider using explorer.exe to use file associations within the guest. Overload with ops to force a more specific 'preCommand'.
_preCommand_MSW() {
	echo -e -n 'start /MAX "" "explorer.exe" '
}

_createHTG_MSW() {
	_setShareMSW
	
	export checkBaseDirRemote=""
	_virtUser "$@"
	#"$sharedHostProjectDir"
	#"${processedArgs[@]}"
	
	_here_bootdisc_startupbat >> "$hostToGuestFiles"/rootmsw.bat
	
	_preCommand_MSW >> "$hostToGuestFiles"/application.bat
	
	_safeEcho_newline "${processedArgs[@]}" >> "$hostToGuestFiles"/application.bat
	 
	echo ""  >> "$hostToGuestFiles"/application.bat
	
	echo -e -n >> "$hostToGuestFiles"/loader.bat
	[[ "$flagShareApp" == "true" ]] && _here_bootdisc_loaderXbat >> "$hostToGuestFiles"/loader.bat
	[[ "$flagShareRoot" == "true" ]] && _here_bootdisc_loaderZbat >> "$hostToGuestFiles"/loader.bat
	
	cat "$hostToGuestFiles"/loader.bat >> "$hostToGuestFiles"/uk4uPhB6.bat
	cat "$hostToGuestFiles"/application.bat >> "$hostToGuestFiles"/uk4uPhB6.bat
	
	_here_bootdisc_shellbat >> "$hostToGuestFiles"/shell.bat
	
	#https://www.cyberciti.biz/faq/howto-unix-linux-convert-dos-newlines-cr-lf-unix-text-format/
	sed -i 's/$'"/`echo \\\r`/" "$hostToGuestFiles"/rootmsw.bat
	sed -i 's/$'"/`echo \\\r`/" "$hostToGuestFiles"/application.bat
	sed -i 's/$'"/`echo \\\r`/" "$hostToGuestFiles"/loader.bat
	sed -i 's/$'"/`echo \\\r`/" "$hostToGuestFiles"/shell.bat
	sed -i 's/$'"/`echo \\\r`/" "$hostToGuestFiles"/uk4uPhB6.bat
}

_setShareUNIX_app() {
	export sharedHostProjectDir="$sharedHostProjectDirDefault"
	export sharedGuestProjectDir="$sharedGuestProjectDirDefault"
	
	export sharedGuestProjectDir="/home/user/project"
}

_setShareUNIX_root() {
	export sharedHostProjectDir="$sharedHostProjectDirDefault"
	export sharedGuestProjectDir="$sharedGuestProjectDirDefault"
	
	export sharedGuestProjectDir="/home/user/project"
	export sharedHostProjectDir=/
}

_setShareUNIX() {
	[[ "$flagShareApp" ]] && _setShareUNIX_app && return
	[[ "$flagShareApp" ]] && _setShareUNIX_root && return
	return 1
}

_createHTG_UNIX() {
	_setShareUNIX
	
	export checkBaseDirRemote=""
	_virtUser "$@"
	#"$sharedHostProjectDir"
	#"${processedArgs[@]}"
	
	_here_bootdisc_statup_xdg >> "$hostToGuestFiles"/startup.desktop
	
	_here_bootdisc_rootnix >> "$hostToGuestFiles"/rootnix.sh
	
	echo '#!/usr/bin/env bash' >> "$hostToGuestFiles"/cmd.sh
	echo "export localPWD=""$localPWD" >> "$hostToGuestFiles"/cmd.sh
	_safeEcho_newline "/media/bootdisc/ubiquitous_bash.sh _dropBootdisc ${processedArgs[@]}" >> "$hostToGuestFiles"/cmd.sh
}

_commandBootdisc() {
	_prepareBootdisc || return 1
	
	export flagShareRoot="false"
	
	#Rigiorously ensure flags will be set properly.
	[[ "$flagShareRoot" != "true" ]] && export flagShareRoot="false"
	[[ "$flagShareRoot" != "true" ]] && export flagShareApp="true"
	
	#Include ubiquitious_bash itself.
	cp "$scriptAbsoluteLocation" "$hostToGuestFiles"/
	"$scriptBin"/.ubrgbin.sh _ubrgbin_cpA "$scriptBin" "$hostToGuestFiles"/_bin
	
	#Process for MSW.
	_createHTG_MSW "$@"
	
	#Process for UNIX.
	_createHTG_UNIX "$@"
	
	#Ensure permissions are correctly set.
	chmod 0755 "$hostToGuestFiles"/_bin/*
	chmod 0755 "$hostToGuestFiles"/*.sh
	chmod 0755 "$hostToGuestFiles"/*.desktop
	chmod 0755 "$hostToGuestFiles"/*.bat
	#chmod 0755 "$hostToGuestFiles"/*
	
	_writeBootdisc || return 1
}

_dropBootdisc() {
	#Detect MSW/Cygwin architecture.
		#Check for QEMU type shared directory, mount if present.
		#Check for VBox type shared directory, mount if present.
	
	#Detect UNIX architecture.
	if ! uname -a | grep -i cygwin > /dev/null 2>&1
	then
		#Attempt to wait for QEMU or VBox type shared directory.
		! mountpoint /home/user/project > /dev/null 2>&1 && sleep 0.3
		! mountpoint /home/user/project > /dev/null 2>&1 && sleep 1
		! mountpoint /home/user/project > /dev/null 2>&1 && sleep 3
		
		for iteration in `seq 1 15`;
		do
			! /bin/mountpoint /home/user/project > /dev/null 2>&1 && sleep 6
		done
		
		! mountpoint /home/user/project > /dev/null 2>&1 && sleep 9
		! mountpoint /home/user/project > /dev/null 2>&1 && sleep 18
		! mountpoint /home/user/project > /dev/null 2>&1 && sleep 27
		! mountpoint /home/user/project > /dev/null 2>&1 && sleep 36
	fi
	sleep 0.3
	
	cd "$localPWD"
	
	"$@"
}





# TODO Launch "_fromImage", transfering "/home/user" to archive, then transfering this archive to "/etc/skel" .
_importHomeUser() {
	true
}

_exportHomeUser() {
	true
}

# TODO To be used by "_userChRoot", binding "/home/user", as an alternative to copying "/etc/skel" .
_bindHomeUser() {
	true
}

_unbindHomeUser() {
	true
}


_test_transferimage() {
	_mustGetSudo
	
	_getDep rsync
}

_toImage() {
	_findInfrastructure_virtImage ${FUNCNAME[0]} "$@"
	[[ "$ubVirtImageLocal" == "false" ]] && return
	
	#_openImage || return 1
	_openChRoot || return 1
	
	#rsync -avx -A -X "$1" "$globalVirtFS"/"$2"
	rsync -avx "$1" "$globalVirtFS"/"$2"
}

_toImageDir() {
	mkdir -p "$globalVirtFS"/"$2"
	_toImage "$1" "$2"
}

_fromImage() {
	#_openImage || return 1
	_openChRoot || return 1
	
	#rsync -avx -A -X "$globalVirtFS""$1" "$2"
	rsync -avx "$globalVirtFS""$1" "$2"
}

_fromImageDir() {
	mkdir -p "$2"
	_fromImage "$1" "$2"
}

_imageToArc() {
	[[ "$globalArcFS" == "" ]] && return 1
	[[ "$globalArcFS" == "/" ]] && return 1
	
	mkdir -p "$globalArcFS" || return 1
	
	_fromImageDir /home/user/. "$globalArcFS"/home/user
	_fromImageDir /etc/skel/. "$globalArcFS"/etc/skel
}

_imageFromArc() {
	[[ "$globalArcFS" == "" ]] && return 1
	[[ "$globalArcFS" == "/" ]] && return 1
	
	mkdir -p "$globalArcFS" || return 1
	
	_toImageDir "$globalArcFS"/home/user/. /home/user
	_toImageDir "$globalArcFS"/etc/skel/. /etc/skel
}

#Example. Translates permissions and copies ".arduino" directory.
_buildFromImage() {
	_mustGetSudo
	
	[[ "$globalBuildDir" == "" ]] && return 1
	[[ "$globalBuildDir" == "/" ]] && return 1
	
	mkdir -p "$globalBuildDir" || return 1
	
	sudo -n "$scriptAbsoluteLocation" _fromImageDir /home/user/.arduino/. "$globalBuildDir"/.arduino
	#sudo -n "$scriptAbsoluteLocation" _fromImageDir /etc/skel/.arduino/. "$globalBuildDir"/.arduino
	
	_safePath "$globalBuildDir"/.arduino && sudo -n chown -R "$USER":"$GROUP" "$globalBuildDir"/.arduino
}

#Example. Translates permissions and copies ".arduino" directory.
_buildToImage() {
	_mustGetSudo
	
	[[ "$globalBuildDir" == "" ]] && return 1
	[[ "$globalBuildDir" == "/" ]] && return 1
	
	mkdir -p "$globalBuildDir" || return 1
	
	sudo -n "$scriptAbsoluteLocation" _toImageDir "$globalBuildDir"/.arduino/. /home/user/.arduino
	sudo -n "$scriptAbsoluteLocation" _toImageDir "$globalBuildDir"/.arduino/. /etc/skel/.arduino
	
	_chroot chown -R user:user /home/user/.arduino
	_chroot chown -R root:root /etc/skel/.arduino
}


_testChRoot() {
	_mustGetSudo
	
	_testGosu || _stop 1
	
	_checkDep gosu-armel
	_checkDep gosu-amd64
	_checkDep gosu-i386
	
	_getDep id
	
	_getDep mount
	_getDep umount
	_getDep mountpoint
	
	_getDep unionfs-fuse
	
}

#Lists all chrooted processes. First parameter is chroot directory. Script might need to run as root.
#Techniques originally released by other authors at http://forums.grsecurity.net/viewtopic.php?f=3&t=1632 .
#"$1" == ChRoot Dir
_listprocChRoot() {
	local absolute1
	absolute1=$(_getAbsoluteLocation "$1")
	PROCS=""
	local currentProcess
	for currentProcess in `ps -o pid -A`; do
		if [ "`readlink /proc/$currentProcess/root`" = "$absolute1" ]; then
			PROCS="$PROCS"" ""$currentProcess"
		fi
	done
	echo "$PROCS"
}

_killprocChRoot() {
	local chrootKillSignal
	chrootKillSignal="$1"
	
	local chrootKillDir
	chrootKillDir="$2"
	
	chrootprocs=$(_listprocChRoot "$chrootKillDir")
	[[ "$chrootprocs" == "" ]] && return 0
	sudo -n kill -"$chrootKillSignal" "$chrootprocs" >/dev/null 2>&1
	sleep 0.1
	
	chrootprocs=$(_listprocChRoot "$chrootKillDir")
	[[ "$chrootprocs" == "" ]] && return 0
	sudo -n kill -"$chrootKillSignal" "$chrootprocs" >/dev/null 2>&1
	sleep 0.3
	
	[[ "$EMERGENCYSHUTDOWN" == "true" ]] && return 1
	
	chrootprocs=$(_listprocChRoot "$chrootKillDir")
	[[ "$chrootprocs" == "" ]] && return 0
	sudo -n kill -"$chrootKillSignal" "$chrootprocs" >/dev/null 2>&1
	sleep 1
	
	chrootprocs=$(_listprocChRoot "$chrootKillDir")
	[[ "$chrootprocs" == "" ]] && return 0
	sudo -n kill -"$chrootKillSignal" "$chrootprocs" >/dev/null 2>&1
	sleep 3
	
	chrootprocs=$(_listprocChRoot "$chrootKillDir")
	[[ "$chrootprocs" == "" ]] && return 0
	sudo -n kill -"$chrootKillSignal" "$chrootprocs" >/dev/null 2>&1
	sleep 9
	
	#chrootprocs=$(_listprocChRoot "$chrootKillDir")
	#[[ "$chrootprocs" == "" ]] && return 0
	#sudo -n kill -"$chrootKillSignal" "$chrootprocs" >/dev/null 2>&1
	#sleep 18
}

#End user and diagnostic function, shuts down all processes in a chroot.
_stopChRoot() {
	_mustGetSudo
	
	local absolute1
	absolute1=$(_getAbsoluteLocation "$1")
	
	echo "TERMinating all chrooted processes."
	
	_killprocChRoot "TERM" "$absolute1"
	
	echo "KILLing all chrooted processes."
	
	_killprocChRoot "KILL" "$absolute1"
	
	echo "Remaining chrooted processes."
	_listprocChRoot "$absolute1"
	
	echo '-----'
	
}

#"$1" == ChRoot Dir
_mountChRoot() {
	_mustGetSudo
	
	[[ ! -e "$1" ]] && return 1
	
	local absolute1
	absolute1=$(_getAbsoluteLocation "$1")
	
	_bindMountManager "/dev" "$absolute1"/dev
	_bindMountManager "/proc" "$absolute1"/proc
	_bindMountManager "/sys" "$absolute1"/sys
	
	_bindMountManager "/dev/pts" "$absolute1"/dev/pts
	
	_bindMountManager "/tmp" "$absolute1"/tmp
	
	#Provide an shm filesystem at /dev/shm.
	sudo -n mount -t tmpfs -o size=4G tmpfs "$absolute1"/dev/shm
	
	#Install ubiquitous_bash itself to chroot.
	sudo -n mkdir -p "$absolute1"/usr/local/bin/
	sudo -n mkdir -p "$absolute1"/usr/local/share/ubcore/bin/
	
	sudo -n cp "$scriptAbsoluteLocation" "$absolute1"/usr/local/bin/ubiquitous_bash.sh
	sudo -n chmod 0755 "$absolute1"/usr/local/bin/ubiquitous_bash.sh
	sudo -n chown root:root "$absolute1"/usr/local/bin/ubiquitous_bash.sh
	
	if [[ -e "$scriptAbsoluteFolder"/lean.sh ]]
	then
		sudo -n cp "$scriptAbsoluteFolder"/lean.sh "$absolute1"/usr/local/bin/lean.sh
		sudo -n chmod 0755 "$absolute1"/usr/local/bin/lean.sh
		sudo -n chown root:root "$absolute1"/usr/local/bin/lean.sh
	fi
	
	sudo -n cp "$scriptBin"/gosu-armel "$absolute1"/usr/local/share/ubcore/bin/gosu-armel
	sudo -n cp "$scriptBin"/gosu-amd64 "$absolute1"/usr/local/share/ubcore/bin/gosu-amd64
	sudo -n cp "$scriptBin"/gosu-i386 "$absolute1"/usr/local/share/ubcore/bin/gosu-i386
	sudo -n chmod 0755 "$absolute1"/usr/local/share/ubcore/bin/*
	sudo -n chown root:root "$absolute1"/usr/local/share/ubcore/bin/*
	
	#Workaround NetworkManager stealing /etc/resolv.conf with broken symlink.
	if ! _chroot test -f /etc/resolv.conf
	then
		sudo -n mv "$absolute1"/etc/resolv.conf "$absolute1"/etc/resolv.conf.bak > /dev/null 2>&1
		sudo -n rm -f "$absolute1"/etc/resolv.conf > /dev/null 2>&1
	fi
	
	if ! grep '8\.8\.8\.8' "$absolute1"/etc/resolv.conf > /dev/null 2>&1
	then
		echo 'nameserver 8.8.8.8' | sudo tee -a "$absolute1"/etc/resolv.conf > /dev/null 2>&1
	fi
	
	if ! grep '2001\:4860\:4860\:\:8888' "$absolute1"/etc/resolv.conf > /dev/null 2>&1
	then
		echo 'nameserver 2001:4860:4860::8888' | sudo tee -a "$absolute1"/etc/resolv.conf > /dev/null 2>&1
	fi
}

#"$1" == ChRoot Dir
_umountChRoot() {
	_mustGetSudo
	
	[[ ! -e "$1" ]] && return 1
	
	local absolute1
	absolute1=$(_getAbsoluteLocation "$1")
	
	_wait_umount "$absolute1"/home/"$virtGuestUser"/project >/dev/null 2>&1
	_wait_umount "$absolute1"/home/"$virtGuestUser" >/dev/null 2>&1
	_wait_umount "$absolute1"/root/project >/dev/null 2>&1
	_wait_umount "$absolute1"/root >/dev/null 2>&1
	
	_wait_umount "$absolute1"/dev/shm
	_wait_umount "$absolute1"/dev/pts
	
	_wait_umount "$absolute1"/proc
	_wait_umount "$absolute1"/sys
	
	_wait_umount "$absolute1"/tmp
	
	_wait_umount "$absolute1"/dev
	
	_wait_umount "$absolute1" >/dev/null 2>&1
	
}

_readyChRoot() {
	
	local absolute1
	absolute1=$(_getAbsoluteLocation "$1")
	
	#mountpoint "$absolute1" > /dev/null 2>&1 || return 1
	
	mountpoint "$absolute1"/dev > /dev/null 2>&1 || return 1
	mountpoint "$absolute1"/proc > /dev/null 2>&1 || return 1
	mountpoint "$absolute1"/sys > /dev/null 2>&1 || return 1
	
	mountpoint "$absolute1"/dev/pts > /dev/null 2>&1 || return 1
	
	mountpoint "$absolute1"/tmp > /dev/null 2>&1 || return 1
	
	mountpoint "$absolute1"/dev/shm > /dev/null 2>&1 || return 1
	
	return 0
	
}

_mountChRoot_image_raspbian() {
	_mustGetSudo
	
	_start
	
	mkdir -p "$chrootDir"
	
	"$scriptAbsoluteLocation" _checkForMounts "$chrootDir" && _stop 1
	
	if sudo -n losetup -f -P --show "$scriptLocal"/vm-raspbian.img > "$safeTmp"/imagedev 2> /dev/null
	then
		#Preemptively declare device open to prevent potentially dangerous multiple mount attempts.
		#Should now be redundant with use of lock_opening .
		#_createLocked "$lock_open" || _stop 1
		
		sudo -n partprobe > /dev/null 2>&1
		
		cp -n "$safeTmp"/imagedev "$scriptLocal"/imagedev > /dev/null 2>&1 || _stop 1
		
		local chrootimagedev
		chrootimagedev=$(cat "$safeTmp"/imagedev)
		
		local chrootimagepart
		chrootimagepart="$chrootimagedev"p2
		
		local chrootloopdevfs
		chrootloopdevfs=$(eval $(sudo -n blkid "$chrootimagepart" | awk ' { print $3 } '); echo $TYPE)
		
		if [[ "$chrootloopdevfs" == "ext4" ]]
		then
			
			sudo -n mount "$chrootimagepart" "$chrootDir" || _stop 1
			
			mountpoint "$chrootDir" > /dev/null 2>&1 || _stop 1
			
			_mountChRoot "$chrootDir"
			
			_readyChRoot "$chrootDir" || _stop 1
			
			sudo -n cp /usr/bin/qemu-arm-static "$chrootDir"/usr/bin/
			sudo -n cp /usr/bin/qemu-armeb-static "$chrootDir"/usr/bin/
			
			sudo -n cp -n "$chrootDir"/etc/ld.so.preload "$chrootDir"/etc/ld.so.preload.orig
			echo | sudo -n tee "$chrootDir"/etc/ld.so.preload > /dev/null 2>&1
			
			_stop 0
		fi
		
	fi
	
	_stop 1
}

_umountChRoot_directory_raspbian() {
	
	_mustGetSudo
	
	mkdir -p "$chrootDir"
	
	sudo -n cp "$chrootDir"/etc/ld.so.preload.orig "$chrootDir"/etc/ld.so.preload
	
}

_mountChRoot_image_x64() {
	_mustGetSudo
	
	_start
	
	mkdir -p "$chrootDir"
	
	"$scriptAbsoluteLocation" _checkForMounts "$chrootDir" && _stop 1
	
	local chrootvmimage
	[[ -e "$scriptLocal"/vm-x64.img ]] && chrootvmimage="$scriptLocal"/vm-x64.img
	[[ -e "$scriptLocal"/vm.img ]] && chrootvmimage="$scriptLocal"/vm.img
	
	sudo -n losetup -f -P --show "$chrootvmimage" > "$safeTmp"/imagedev 2> /dev/null || _stop 1
	sudo -n partprobe > /dev/null 2>&1
	
	cp -n "$safeTmp"/imagedev "$scriptLocal"/imagedev > /dev/null 2>&1 || _stop 1
	
	local chrootimagedev
	chrootimagedev=$(cat "$safeTmp"/imagedev)
	
	local chrootimagepart
	#chrootimagepart="$chrootimagedev"p2
	chrootimagepart="$chrootimagedev"p1
	
	local chrootloopdevfs
	chrootloopdevfs=$(eval $(sudo -n blkid "$chrootimagepart" | awk ' { print $3 } '); echo $TYPE)
	
	! [[ "$chrootloopdevfs" == "ext4" ]] && _stop 1
	
	sudo -n mount "$chrootimagepart" "$chrootDir" || _stop 1
	
	mountpoint "$chrootDir" > /dev/null 2>&1 || _stop 1
	
	_mountChRoot "$chrootDir"
	
	_readyChRoot "$chrootDir" || _stop 1
	
	_stop 0
}

_umountChRoot_directory_x64() {
	_mustGetSudo
	
	mkdir -p "$chrootDir"
}

_mountChRoot_image() {
	_tryExecFull _hook_systemd_shutdown_action "_closeChRoot_emergency" "$sessionid"
	
	if [[ -e "$scriptLocal"/vm-raspbian.img ]]
	then
		"$scriptAbsoluteLocation" _mountChRoot_image_raspbian
		return "$?"
	fi
	
	if [[ -e "$scriptLocal"/vm-x64.img ]]
	then
		"$scriptAbsoluteLocation" _mountChRoot_image_x64
		return "$?"
	fi
	
	#Default "vm.img" will be operated on as x64 image.
	"$scriptAbsoluteLocation" _mountChRoot_image_x64
	return "$?"
}

_umountChRoot_directory() {
	if [[ -e "$scriptLocal"/vm-raspbian.img ]]
	then
		"$scriptAbsoluteLocation" _umountChRoot_directory_raspbian || return "$?"
	fi
	
	if [[ -e "$scriptLocal"/vm-x64.img ]]
	then
		"$scriptAbsoluteLocation" _umountChRoot_directory_x64 || return "$?"
	fi
	
	#Default "vm.img" will be operated on as x64 image.
	"$scriptAbsoluteLocation" _umountChRoot_directory_x64 || return "$?"
	
	_stopChRoot "$1"
	_umountChRoot "$1"
	mountpoint "$1" > /dev/null 2>&1 && sudo -n umount "$1"
	
	"$scriptAbsoluteLocation" _checkForMounts "$1" && return 1
}

_umountChRoot_image() {
	_mustGetSudo || return 1
	
	_umountChRoot_directory "$chrootDir" && return 1
	
	local chrootimagedev
	chrootimagedev=$(cat "$scriptLocal"/imagedev)
	
	sudo -n losetup -d "$chrootimagedev" > /dev/null 2>&1 || return 1
	sudo -n partprobe > /dev/null 2>&1
	
	rm -f "$scriptLocal"/imagedev || return 1
	
	rm -f "$lock_quicktmp" > /dev/null 2>&1
	
	rm -f "$permaLog"/gsysd.log > /dev/null 2>&1
	
	return 0
}

_waitChRoot_opening() {
	_readyChRoot "$chrootDir" && return 0
	sleep 1
	_readyChRoot "$chrootDir" && return 0
	sleep 3
	_readyChRoot "$chrootDir" && return 0
	sleep 9
	_readyChRoot "$chrootDir" && return 0
	sleep 27
	_readyChRoot "$chrootDir" && return 0
	sleep 81
	_readyChRoot "$chrootDir" && return 0
	
	return 1
}

_waitChRoot_closing() {
	_readyChRoot "$chrootDir" || return 0
	sleep 1
	_readyChRoot "$chrootDir" || return 0
	sleep 3
	_readyChRoot "$chrootDir" || return 0
	sleep 9
	_readyChRoot "$chrootDir" || return 0
	sleep 27
	_readyChRoot "$chrootDir" || return 0
	sleep 81
	_readyChRoot "$chrootDir" || return 0
	
	return 1
}

_openChRoot() {
	export specialLock="$lock_open_chroot"
	_open _waitChRoot_opening _mountChRoot_image
}

_closeChRoot() {
	_findInfrastructure_virtImage ${FUNCNAME[0]} "$@"
	[[ "$ubVirtImageLocal" == "false" ]] && return
	
	export specialLock="$lock_open_chroot"
	if [[ "$1" == "--force" ]]
	then
		_close --force _waitChRoot_closing _umountChRoot_image
		return
	fi
	
	_close _waitChRoot_closing _umountChRoot_image
}

_haltAllChRoot() {
	find "$scriptAbsoluteFolder"/v_*/fs -maxdepth 1 -type d -exec "$scriptAbsoluteLocation" _umountChRoot_directory {} \;
	find "$scriptAbsoluteFolder"/v_*/tmp -maxdepth 1 -type d -exec sudo -n umount {} \;
	find "$scriptAbsoluteFolder"/v_*/ -maxdepth 12 -type d | head -n 48 | tac | xargs rmdir
	
	"$scriptAbsoluteLocation" _closeChRoot --force
	
	#Closing file may remain if chroot was not open to begin with. Since haltAllChRoot is usually called for forced/emergency shutdown purposes, clearing the resultant lock file is usually safe.
	rm -f "$lock_closing"
}

#Fast dismount of all ChRoot filesystems/instances and cleanup of lock files. Specifically intended to act on SIGTERM or during system(d) shutdown, when time and disk I/O may be limited.
# TODO Use a tmpfs mount to track reboots (with appropriate BSD/Linux/Solaris checking) in the first place.
#"$1" == sessionid (optional override for cleaning up stale systemd files)
_closeChRoot_emergency() {
	_checkSpecialLocks "$lock_open_chroot"
	
	if [[ -e "$instancedVirtFS" ]]
	then
		_stopChRoot "$instancedVirtFS" >> "$logTmp"/usrchrt.log 2>&1
		_umountChRoot_project >> "$logTmp"/usrchrt.log 2>&1
		_umountChRoot_user_home >> "$logTmp"/usrchrt.log 2>&1
		_umountChRoot_user >> "$logTmp"/usrchrt.log 2>&1
		
		_rm_ubvrtusrChRoot
		
		_stop_virt_instance >> "$logTmp"/usrchrt.log 2>&1
	fi
	
	#Not called by systemd, AND instanced directories still mounted, do not globally halt all. (optional)
	#[[ "$1" == "" ]] && find "$scriptAbsoluteFolder"/v_* -maxdepth 1 -type d > /dev/null && return 0
	
	#Not called by systemd, do not globally halt all.
	[[ "$1" == "" ]] && return 0
	
	! _readLocked "$lock_open" && ! find "$scriptAbsoluteFolder"/v_*/fs -maxdepth 1 -type d && return 0
	_readLocked "$lock_closing" && return 1
	_readLocked "$lock_opening" && return 1
	
	_readLocked "$lock_emergency" && return 0
	_createLocked "$lock_emergency"
	
	_haltAllChRoot
	
	rm -f "$lock_emergency" || return 1
	
	
	local hookSessionid
	hookSessionid="$sessionid"
	[[ "$1" != "" ]] && hookSessionid="$1"
	_tryExecFull _unhook_systemd_shutdown "$hookSessionid"
	
}

#Debugging function.
_removeChRoot() {
	_haltAllChRoot
	
	rm -f "$lock_closing"
	rm -f "$lock_opening"
	rm -f "$lock_instancing"
	
	rm -f "$globalVirtDir"/_ubvrtusr
	
	
}

_chroot() {
	
	[[ ! -e "$chrootDir"/bin/bash ]] && return 1
	
	_mustGetSudo
	
	#cd "$chrootDir"
	
	local chrootExitStatus
	
	sudo -n env -i HOME="/root" TERM="${TERM}" SHELL="/bin/bash" PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" DISPLAY="$DISPLAY" XSOCK="$XSOCK" XAUTH="$XAUTH" localPWD="$localPWD" hostArch=$(uname -m) virtSharedUser="$virtGuestUser" $(sudo -n which chroot) "$chrootDir" "$@"
	
	chrootExitStatus="$?"
	
	return "$chrootExitStatus"
	
}


_mountChRoot_userAndHome() {
	
	sudo -n mount -t tmpfs -o size=4G,uid="$HOST_USER_ID",gid="$HOST_GROUP_ID" tmpfs "$instancedVirtTmp"
	
	#_bindMountManager "$globalVirtFS" "$instancedVirtFS" || return 1
	
	#_bindMountManager "$instancedVirtTmp" "$instancedVirtHome" || return 1
	
	
	#Remove directories that interfere with union mounting.
	rmdir "$instancedProjectDir"
	rmdir "$instancedVirtHome"
	###rmdir "$instancedVirtHomeRef"
	rmdir "$instancedVirtFS"/home
	rmdir "$instancedVirtFS"/root > /dev/null 2>&1
	
	# TODO Device Mapper snapshot ChRoot instancing alternative. Disadvantage of not allowing the root filesystem to be simultaneously mounted read-write.
	# TODO Develop a function to automatically select whatever unionfs equivalent may be supported by the host.
	#sudo /bin/mount -t unionfs -o dirs="$instancedVirtTmp":"$globalVirtFS"=ro unionfs "$instancedVirtFS"
	sudo -n unionfs-fuse -o cow,allow_other,use_ino,suid,dev "$instancedVirtTmp"=RW:"$globalVirtFS"=RO "$instancedVirtFS"
	#sudo unionfs -o dirs="$instancedVirtTmp":"$globalVirtFS"=ro "$instancedVirtFS"
	sudo -n chown "$USER":"$USER" "$instancedVirtFS"
	
	#unionfs-fuse -o cow,max_files=32768 -o allow_other,use_ino,suid,dev,nonempty /u/host/etc=RW:/u/group/etc=RO:/u/common/etc=RO /u/union/etc
	
	mkdir -p "$instancedProjectDir"
	mkdir -p "$instancedVirtHome"
	###mkdir -p "$instancedVirtHomeRef"
	
	return 0
}

_mountChRoot_project() {
	#if [[ ! -e "$0" ]]
	#then
	#	return 1
	#fi
	
	if [[ "$sharedHostProjectDir" == "" ]]
	then
		return 1
	fi
	
	if [[ "$sharedHostProjectDir" == "/" ]]
	then
		return 1
	fi
	
	#Blacklist.
	[[ "$sharedHostProjectDir" == "/home" ]] && return 1
	[[ "$sharedHostProjectDir" == "/home/" ]] && return 1
	[[ "$sharedHostProjectDir" == "/home/$USER" ]] && return 1
	[[ "$sharedHostProjectDir" == "/home/$USER/" ]] && return 1
	[[ $(id -u) != 0 ]] && [[ "$sharedHostProjectDir" == "/$USER" ]] && return 1
	[[ $(id -u) != 0 ]] && [[ "$sharedHostProjectDir" == "/$USER/" ]] && return 1
	
	[[ "$sharedHostProjectDir" == "/tmp" ]] && return 1
	[[ "$sharedHostProjectDir" == "/tmp/" ]] && return 1
	
	[[ $(id -u) != 0 ]] && [[ "$sharedHostProjectDir" == "$HOME" ]] && return 1
	[[ $(id -u) != 0 ]] && [[ "$sharedHostProjectDir" == "$HOME/" ]] && return 1
	
	#Whitelist.
	local safeToMount=false
	
	local safeScriptAbsoluteFolder="$_getScriptAbsoluteFolder"
	
	[[ "$sharedHostProjectDir" == "./"* ]] && [[ "$PWD" == "$safeScriptAbsoluteFolder"* ]] && safeToMount="true"
	
	[[ "$sharedHostProjectDir" == "$safeScriptAbsoluteFolder"* ]] && safeToMount="true"
	
	[[ "$sharedHostProjectDir" == "/home/$USER"* ]] && safeToMount="true"
	[[ "$sharedHostProjectDir" == "/root"* ]] && safeToMount="true"
	
	[[ "$sharedHostProjectDir" == "/tmp/"* ]] && safeToMount="true"
	
	[[ "$safeToMount" == "false" ]] && return 1
	
	#Safeguards/
	#[[ -d "$sharedHostProjectDir" ]] && find "$sharedHostProjectDir" | grep -i '\.git$' >/dev/null 2>&1 && return 1
	
	#Validate necessary tools were available for path building and checks.
	_checkDep realpath
	_checkDep readlink
	_checkDep dirname
	_checkDep basename
	
	sudo -n unionfs-fuse -o allow_other,use_ino,suid,dev "$sharedHostProjectDir"=RW "$instancedProjectDir"
	sudo -n chown "$USER":"$USER" "$instancedProjectDir"
	
	#_bindMountManager "$sharedHostProjectDir" "$instancedProjectDir" || return 1
	
}

_umountChRoot_project() {
	
	_wait_umount "$instancedProjectDir"
	
}

_mountChRoot_userDirs() {
	mkdir -p "$HOME"/Downloads
	sudo -n mkdir -p "$instancedDownloadsDir"
	sudo -n unionfs-fuse -o allow_other,use_ino,suid,dev "$HOME"/Downloads=RW "$instancedDownloadsDir"
	sudo -n chown "$USER":"$USER" "$instancedDownloadsDir"
	
}

_umountChRoot_userDirs() {
	_wait_umount "$instancedDownloadsDir"
	sudo -n rmdir "$instancedDownloadsDir"
	
}

#No production use. Already supported by bind mount of full "/tmp". Kept for reference only.
_mountChRoot_X11() {
	_bindMountManager "$XSOCK" "$instancedVirtFS"/"$XSOCK"
	_bindMountManager "$XSOCK" "$instancedVirtFS"/"$XAUTH"
}

#No production use. Already supported by bind mount of full "/tmp". Kept for reference only.
_umountChRoot_X11() {
	_wait_umount "$instancedVirtFS"/"$XSOCK"
	_wait_umount "$instancedVirtFS"/"$XAUTH"
}


_umountChRoot_user() {
	
	mountpoint "$instancedVirtFS" > /dev/null 2>&1 || return 1
	#_umountChRoot "$instancedVirtFS"
	_wait_umount "$instancedVirtFS"
	
}

_umountChRoot_user_home() {
	
	_wait_umount "$instancedVirtHome" || return 1
	mountpoint "$instancedVirtHome" > /dev/null 2>&1 && return 1
	
	return 0
	
}

_checkBaseDirRemote_chroot() {
	
	[[ -e "$chrootDir"/"$1" ]] || return 1
	return 0
	
}



_rm_ubvrtusrChRoot() {
	
	sudo -n rmdir "$sharedGuestProjectDir" > /dev/null 2>&1
	sudo -n rmdir "$instancedVirtHome"/"$virtGuestUser"/project > /dev/null 2>&1
	sudo -n rmdir "$instancedVirtHome"/"$virtGuestUser" > /dev/null 2>&1
	sudo -n rmdir "$instancedVirtHome" > /dev/null 2>&1
	###sudo -n rmdir "$instancedVirtHomeRef"/project > /dev/null 2>&1
	###sudo -n rmdir "$instancedVirtHomeRef"/"$virtGuestUser"/project > /dev/null 2>&1
	###sudo -n rmdir "$instancedVirtHomeRef"/"$virtGuestUser" > /dev/null 2>&1
	###sudo -n rmdir "$instancedVirtHomeRef" > /dev/null 2>&1
	
}



_ubvrtusrChRoot_report_failure() {
	
	echo -n "ubvrtusr     ""$1"
	echo -e -n '\t'
	shift
	
	echo -n "$1"
	echo -e -n '\t'
	shift
	
	shift
	echo "$@"
	
	return 0
	
}

_ubvrtusrChRoot_check() {
	#Diagnostics.
	echo '#####ubvrtusr     checks'
	
	local internalFailure
	internalFailure=false
	
	###! [[ -e "$globalVirtFS"/"$virtGuestHomeRef" ]] && _ubvrtusrChRoot_report_failure "nohome" "$virtGuestHomeRef" '[[ -e "$virtGuestHomeRef" ]]' && internalFailure=true
	
	! _chroot id -u "$virtGuestUser" > /dev/null 2>&1 && _ubvrtusrChRoot_report_failure "no guest user" "$virtGuestUser" '_chroot id -u "$virtGuestUser"' && internalFailure=true
	
	! [[ $(_chroot id -u "$virtGuestUser") == "$HOST_USER_ID" ]] && _ubvrtusrChRoot_report_failure "bad uid" $(_chroot id -u "$virtGuestUser") '[[ $(_chroot id -u "$virtGuestUser") == "$HOST_USER_ID" ]]' && internalFailure=true
	
	! [[ $(_chroot id -g "$virtGuestUser") == "$HOST_GROUP_ID" ]] && _ubvrtusrChRoot_report_failure "bad gid" $(_chroot id -g "$virtGuestUser") '[[ $(_chroot id -g "$virtGuestUser") == "$HOST_GROUP_ID" ]]' && internalFailure=true
	
	echo '#####ubvrtusr     checks'
	
	 [[ "$internalFailure" == "true" ]] && return 1
	 return 0
}

_ubvrtusrChRoot() {
	
	#If root, discontinue.
	[[ $(id -u) == 0 ]] && return 0
	
	#If user correctly setup, discontinue. Check multiple times before recreating user.
	local iterationCount
	iterationCount=0
	while [[ "$iterationCount" -lt "3" ]]
	do
		_ubvrtusrChRoot_check && return 0
		
		let iterationCount="$iterationCount"+1
		sleep 0.3
	done
	
	## Lock file. Not done with _waitFileCommands because there is nither an obvious means, nor an obviously catastrophically critical requirement, to independently check for completion of related useradd/mod/del operations.
	_waitFile "$globalVirtDir"/_ubvrtusr || return 1
	echo > "$globalVirtDir"/quicktmp
	mv -n "$globalVirtDir"/quicktmp "$globalVirtDir"/_ubvrtusr > /dev/null 2>&1 || return 1
	
	_chroot userdel -r "$virtGuestUser"
	_rm_ubvrtusrChRoot
	
	_chroot groupadd -g "$HOST_GROUP_ID" -o "$virtGuestUser"
	_chroot useradd --shell /bin/bash -u "$HOST_USER_ID" -g "$HOST_GROUP_ID" -o -c "" -m "$virtGuestUser" || return 1
	
	_chroot usermod -a -G video "$virtGuestUser" > /dev/null 2>&1 || return 1
	
	_chroot chown "$virtGuestUser":"$virtGuestUser" "$virtGuestHome" > /dev/null 2>&1
	
	sudo -n mkdir -p "$globalVirtFS""$virtGuestHome"
	###sudo -n mkdir -p "$globalVirtFS""$virtGuestHomeRef"
	###sudo -n cp -a "$globalVirtFS""$virtGuestHome"/. "$globalVirtFS""$virtGuestHomeRef"/
	###echo sudo -n cp -a "$globalVirtFS""$virtGuestHome"/. "$globalVirtFS""$virtGuestHomeRef"/
	###_chroot chown "$virtGuestUser":"$virtGuestUser" "$virtGuestHomeRef" > /dev/null 2>&1
	
	rm -f "$globalVirtDir"/_ubvrtusr > /dev/null 2>&1 || return 1
	
	return 0
}

_userChRoot() {
	_findInfrastructure_virtImage ${FUNCNAME[0]} "$@"
	[[ "$ubVirtImageLocal" == "false" ]] && return
	
	_start
	_start_virt_all
	export chrootDir="$globalVirtFS"
	
	_mustGetSudo || _stop 1
	
	
	_checkDep mountpoint >> "$logTmp"/usrchrt.log 2>&1 || _stop 1
	mountpoint "$instancedVirtDir" > /dev/null 2>&1 && _stop 1
	mountpoint "$instancedVirtFS" > /dev/null 2>&1 && _stop 1
	mountpoint "$instancedVirtTmp" > /dev/null 2>&1 && _stop 1
	mountpoint "$instancedVirtHome" > /dev/null 2>&1 && _stop 1
	
	"$scriptAbsoluteLocation" _openChRoot >> "$logTmp"/usrchrt.log 2>&1 || _stop 1
	
	_tryExecFull _hook_systemd_shutdown_action "_closeChRoot_emergency" "$sessionid"
	
	
	_ubvrtusrChRoot  >> "$logTmp"/usrchrt.log 2>&1 || _stop 1
	
	_mountChRoot_userAndHome >> "$logTmp"/usrchrt.log 2>&1 || _stop 1
	###[[ $(id -u) != 0 ]] && cp -a "$instancedVirtHomeRef"/. "$instancedVirtHome"/ >> "$logTmp"/usrchrt.log 2>&1
	export chrootDir="$instancedVirtFS"
	
	
	export checkBaseDirRemote=_checkBaseDirRemote_chroot
	_virtUser "$@" >> "$logTmp"/usrchrt.log 2>&1
	
	#_mountChRoot_X11
	
	_mountChRoot_project >> "$logTmp"/usrchrt.log 2>&1 || _stop 1
	_chroot chown "$virtGuestUser":"$virtGuestUser" "$sharedGuestProjectDir" >> "$logTmp"/usrchrt.log 2>&1
	
	#####
	_mountChRoot_userDirs
	
	
	
	_chroot /bin/bash /usr/local/bin/ubiquitous_bash.sh _dropChRoot "${processedArgs[@]}"
	local userChRootExitStatus="$?"
	
	_stopChRoot "$instancedVirtFS" >> "$logTmp"/usrchrt.log 2>&1
	
	
	
	
	_umountChRoot_userDirs
	#####
	
	#_umountChRoot_X11
	
	_umountChRoot_project >> "$logTmp"/usrchrt.log 2>&1
	_umountChRoot_user_home >> "$logTmp"/usrchrt.log 2>&1 || _stop 1
	_umountChRoot_user >> "$logTmp"/usrchrt.log 2>&1 || _stop 1
	
	_rm_ubvrtusrChRoot
	
	"$scriptAbsoluteLocation" _checkForMounts "$instancedVirtFS" >> "$logTmp"/usrchrt.log 2>&1 && _stop 1
	
	_stop_virt_instance >> "$logTmp"/usrchrt.log 2>&1
	_stop "$userChRootExitStatus"
}

_removeUserChRoot_sequence() {
	## Lock file. Not done with _waitFileCommands because there is nither an obvious means, nor an obviously catastrophically critical requirement, to independently check for completion of related useradd/mod/del operations.
	_waitFile "$globalVirtDir"/_ubvrtusr || return 1
	echo > "$globalVirtDir"/quicktmp
	mv -n "$globalVirtDir"/quicktmp "$globalVirtDir"/_ubvrtusr > /dev/null 2>&1 || return 1
	
	
	_chroot userdel -r "$virtGuestUser" > /dev/null 2>&1
	###[[ -d "$chrootDir""$virtGuestHomeRef" ]] && sudo -n "$scriptAbsoluteLocation" _safeRMR "$chrootDir""$virtGuestHomeRef"
	
	_rm_ubvrtusrChRoot
	
	rm -f "$globalVirtDir"/_ubvrtusr > /dev/null 2>&1 || return 1
}

_removeUserChRoot() {
	"$scriptAbsoluteLocation" _openChRoot || return 1
	
	_removeUserChRoot_sequence
	
	"$scriptAbsoluteLocation" _closeChRoot || return 1
} 

_dropChRoot() {
	
	# Change to localPWD or home.
	cd "$localPWD"
	
	"$scriptAbsoluteLocation" _gosuExecVirt cp -r /etc/skel/. "$virtGuestHomeDrop"
	
	"$scriptAbsoluteLocation" _gosuExecVirt "$scriptAbsoluteLocation" _setupUbiquitous_nonet
	
	# Drop to user ubvrtusr, using gosu.
	_gosuExecVirt "$@"
}

#No production use. Kept for reference only.
###_prepareChRootUser() {
	
	#_gosuExecVirt cp -r /etc/skel/. /home/
	
	#cp -a /home/"$virtGuestUser".ref/. /home/"$virtGuestUser"/
	#chown "$virtGuestUser":"$virtGuestUser" /home/"$virtGuestUser"
	
	###true
	
###}


#Ensures dependencies are met for raspi-on-raspi virtualization.
_testQEMU_raspi-raspi() {
	true
}

_testQEMU_hostArch_x64-raspi() {
	local hostArch
	hostArch=$(uname -m)
	
	if [[ "$hostArch" != "x86_64" ]]
	then
		return 1
	fi
	
	return 0
}

_testQEMU_x64-raspi() {
	
	_testQEMU_x64-x64
	_getDep qemu-arm-static
	_getDep qemu-armeb-static
	
	_mustGetSudo
	
	! _testQEMU_hostArch_x64-raspi && echo "warn: not checking x64 translation" && return 0
	
	if ! sudo -n /usr/sbin/update-binfmts --display | grep qemu > /dev/null 2>&1
	then
		echo 'binfmts does not mention qemu-arm'
		_stop 1
	fi
	
	if ! sudo -n /usr/sbin/update-binfmts --display | grep qemu-armeb-static > /dev/null 2>&1
	then
		echo 'binfmts does not mention qemu-armeb'
		_stop 1
	fi
}



_testQEMU_hostArch_x64_hardwarevt() {
	#[[ -e /dev/kvm ]] && (grep -i svm /proc/cpuinfo > /dev/null 2>&1 || grep -i vmx /proc/cpuinfo > /dev/null 2>&1)
	
	! [[ -e /dev/kvm ]] && return 1
	
	grep -i svm /proc/cpuinfo > /dev/null 2>&1 && return 0
	grep -i vmx /proc/cpuinfo > /dev/null 2>&1 && return 0
	
	return 1
}

_testQEMU_hostArch_x64_nested() {
	grep '1' /sys/module/kvm_amd/parameters/nested > /dev/null 2>&1 && return 0
	grep 'Y' /sys/module/kvm_amd/parameters/nested > /dev/null 2>&1 && return 0
	grep '1' /sys/module/kvm_intel/parameters/nested > /dev/null 2>&1 && return 0
	grep 'Y' /sys/module/kvm_intel/parameters/nested > /dev/null 2>&1 && return 0
	
	return 1
}

_testQEMU_hostArch_x64-x64() {
	local hostArch
	hostArch=$(uname -m)
	
	if [[ "$hostArch" != "x86_64" ]]
	then
		return 1
	fi
	
	return 0
}

_testQEMU_x64-x64() {
	_testQEMU_hostArch_x64-x64 || echo "warn: no native x64"
	_testQEMU_hostArch_x64_hardwarevt || echo "warn: no x64 vt"
	_testQEMU_hostArch_x64_nested || echo "warn: no nested x64"
	
	_getDep qemu-system-x86_64
	_getDep qemu-img
	
	_getDep smbd
}

_qemu-system() {
	qemu-system-x86_64 "$@"
}

#Overload this function, or the guestArch variable, to configure QEMU to  guest with a specif
_qemu() {
	local qemuHostArch
	qemuHostArch=$(uname -m)
	[[ "$qemuHostArch" == "" ]] && qemuGuestArch="$qemuHostArch"
	 _messagePlain_probe 'qemuGuestArch= '"$qemuGuestArch"
	
	local qemuExitStatus
	
	[[ "$qemuHostArch" == "x86_64" ]] && _messagePlain_probe '>qemu= qemu-system-x86_64' && qemu-system-x86_64 "$@"
	qemuExitStatus="$?"
	
	
	return "$qemuExitStatus"
}

_integratedQemu() {
	_messagePlain_nominal 'init: _integratedQemu'
	
	! mkdir -p "$instancedVirtDir" && _messagePlain_bad 'fail: mkdir -p instancedVirtDir= '"$instancedVirtDir" && _stop 1
	
	! _commandBootdisc "$@" && _messagePlain_bad 'fail: _commandBootdisc' && _stop 1
	
	#qemu-system-x86_64 -snapshot -machine accel=kvm -drive format=raw,file="$scriptLocal"/vm.img -drive file="$hostToGuestISO",media=cdrom -boot c -m 768
	
	#https://wiki.qemu.org/Documentation/9psetup#Mounting_the_shared_path
	#qemu-system-x86_64 -snapshot -machine accel=kvm -drive format=raw,file="$scriptLocal"/vm.img -drive file="$hostToGuestISO",media=cdrom -boot c -m 768 -fsdev local,id=appFolder,path="$sharedHostProjectDir",security_model=mapped,writeout=writeout
	
	#https://askubuntu.com/questions/614098/unable-to-get-execute-bit-on-samba-share-working-with-windows-7-client
	#https://unix.stackexchange.com/questions/165554/shared-folder-between-qemu-windows-guest-and-linux-host
	#https://linux.die.net/man/1/qemu-kvm
	
	if _testQEMU_hostArch_x64_nested
	then
		_messagePlain_good 'supported: nested x64'
		qemuArgs+=(-cpu host)
	else
		_messagePlain_warn 'warn: no nested x64'
	fi
	
	local hostThreadCount=$(cat /proc/cpuinfo | grep MHz | wc -l)
	[[ "$hostThreadCount" -ge "4" ]] && [[ "$hostThreadCount" -lt "8" ]] && _messagePlain_probe 'cpu: >4' && qemuArgs+=(-smp 4)
	[[ "$hostThreadCount" -ge "8" ]] && _messagePlain_probe 'cpu: >6' && qemuArgs+=(-smp 6)
	
	qemuUserArgs+=(-drive format=raw,file="$scriptLocal"/vm.img -drive file="$hostToGuestISO",media=cdrom -boot c)
	
	[[ "$vmMemoryAllocation" == "" ]] && vmMemoryAllocation="$vmMemoryAllocationDefault"
	qemuUserArgs+=(-m "$vmMemoryAllocation")
	
	[[ "$qemuUserArgs_netRestrict" == "" ]] && qemuUserArgs_netRestrict="n"
	
	qemuUserArgs+=(-net nic,model=rtl8139 -net user,restrict="$qemuUserArgs_netRestrict",smb="$sharedHostProjectDir")
	
	qemuArgs+=(-usbdevice tablet)
	
	qemuArgs+=(-vga cirrus)
	
	[[ "$qemuArgs_audio" == "" ]] && qemuArgs+=(-device ich9-intel-hda -device hda-duplex)
	
	qemuArgs+=(-show-cursor)
	
	if _testQEMU_hostArch_x64_hardwarevt
	then
		_messagePlain_good 'found: kvm'
		qemuArgs+=(-machine accel=kvm)
	else
		_messagePlain_warn 'missing: kvm'
	fi
	
	qemuArgs+=("${qemuSpecialArgs[@]}" "${qemuUserArgs[@]}")
	
	_messagePlain_probe _qemu "${qemuArgs[@]}"
	_qemu "${qemuArgs[@]}"
	
	_safeRMR "$instancedVirtDir" || _stop 1
}

#"${qemuSpecialArgs[@]}" == ["-snapshot "]
_userQemu_sequence() {
	unset qemuSpecialArgs
	
	qemuSpecialArgs+=("-snapshot")
	
	export qemuSpecialArgs
	
	_start
	
	_integratedQemu "$@" || _stop 1
	
	_stop
}

_userQemu() {
	_findInfrastructure_virtImage ${FUNCNAME[0]} "$@"
	[[ "$ubVirtImageLocal" == "false" ]] && return
	
	"$scriptAbsoluteLocation" _userQemu_sequence "$@"
}

_editQemu_sequence() {
	unset qemuSpecialArgs
	
	export qemuSpecialArgs
	
	_start
	
	#_messageNormal "Checking lock."
	#_readLocked "$scriptLocal"/_qemuEdit && _messageError 'lock: _qemuEdit' && _stop 1
	#! _createLocked "$scriptLocal"/_qemuEdit  && _messageError 'lock: _qemuEdit' && _stop 1
	
	_messageNormal "Checking lock and conflicts."
	export specialLock="$lock_open_qemu"
	! _open true true && _messageError 'FAIL' && _stop 1
	
	_messageNormal "Launch: _integratedQemu."
	! _integratedQemu "$@" && _messageError 'FAIL' && _stop 1
	
	rm -f "$scriptLocal"/_qemuEdit > /dev/null 2>&1
	export specialLock="$lock_open_qemu"
	! _close true true && _messageError 'FAIL' && _stop 1
	
	_stop
}

_editQemu() {
	_findInfrastructure_virtImage ${FUNCNAME[0]} "$@"
	[[ "$ubVirtImageLocal" == "false" ]] && return
	
	"$scriptAbsoluteLocation" _editQemu_sequence "$@"
}

_testVBox() {
	_getDep VirtualBox
	_getDep VBoxSDL
	_getDep VBoxManage
	_getDep VBoxHeadless
	
	#sudo -n checkDep dkms
	
	! _noFireJail virtualbox && _stop 1
}


_checkVBox_raw() {
	#Use existing VDI image if available.
	[[ -e "$scriptLocal"/vm.vdi ]] && _messagePlain_bad 'conflict: vm.vdi' && return 1
	[[ ! -e "$scriptLocal"/vm.img ]] && _messagePlain_bad 'missing: vm.img' && return 1
	
	return 0
}

# WARNING
# Per VirtualBox developers, "This is a development tool and shall only be used to analyse problems. It is completely unsupported and will change in incompatible ways without warning."
# If that happens, this function will be revised quickly, possibly to the point of generating the VMDK file itself with a here document instead of VirtualBox commands. See "_diag/data/vmdkRawExample".
_create_vbox_raw() {
	if ! VBoxManage internalcommands createrawvmdk -filename "$vboxRaw" -rawdisk "$1" > "$vboxRaw".log
	then
		_messagePlain_bad 'fail: 'VBoxManage internalcommands createrawvmdk -filename "$vboxRaw" -rawdisk "$1" '>' "$vboxRaw".log
	fi
	return 0
}


_mountVBox_raw_sequence() {
	_messagePlain_nominal 'start: _mountVBox_raw_sequence'
	_start
	
	_checkVBox_raw || _stop 1
	
	! _wantSudo && _messagePlain_bad 'bad: sudo' && return 1
	
	_prepare_instance_vbox
	
	rm -f "$vboxRaw" > /dev/null 2>&1
	
	_messagePlain_nominal 'Creating loopback.'
	! sudo -n losetup -f -P --show "$scriptLocal"/vm.img > "$safeTmp"/vboxloop 2> /dev/null && _messagePlain_bad 'fail: losetup' && _stop 1
	
	! cp -n "$safeTmp"/vboxloop "$scriptLocal"/vboxloop > /dev/null 2>&1 && _messagePlain_bad 'fail: copy vboxloop' && _stop 1
	
	local vboximagedev
	vboximagedev=$(cat "$safeTmp"/vboxloop)
	
	if _tryExecFull _hook_systemd_shutdown_action "_closeVBoxRaw" "$sessionid"
	then
		_messagePlain_good 'pass: _hook_systemd_shutdown_action'
	else
		_messagePlain_bad 'fail: _hook_systemd_shutdown_action'
	fi
	
	! sudo -n chown "$USER" "$vboximagedev" && _messagePlain_bad 'chown vboximagedev= '"$vboximagedev" && _stop 1
	
	_messagePlain_nominal 'Creating VBoxRaw.'
	_create_vbox_raw "$vboximagedev"
	
	_messagePlain_nominal 'stop: _mountVBox_raw_sequence'
	_safeRMR "$instancedVirtDir" || _stop 1
	_stop 0
}

_mountVBox_raw() {
	"$scriptAbsoluteLocation" _mountVBox_raw_sequence
	return "$?"
}

_waitVBox_opening() {
	! [[ -e "$vboxRaw" ]] && return 1
	! [[ -e "$scriptLocal"/vboxloop ]] && return 1
	
	local vboximagedev=$(cat "$safeTmp"/vboxloop)
	! [[ -e "$vboximagedev" ]] && return 1
}

_umountVBox_raw() {
	local vboximagedev
	vboximagedev=$(cat "$scriptLocal"/vboxloop)
	
	sudo -n losetup -d "$vboximagedev" > /dev/null 2>&1 || return 1
	
	rm -f "$scriptLocal"/vboxloop > /dev/null 2>&1
	rm -f "$vboxRaw" > /dev/null 2>&1
	rm -f "$vboxRaw".log > /dev/null 2>&1
	
	return 0
}

_waitVBox_closing() {
	true
}

_openVBoxRaw() {
	export specialLock="$lock_open_vbox"
	
	_checkVBox_raw || _stop 1
	
	_messagePlain_nominal 'launch: _open _waitVBox_opening _mountVBox_raw'
	
	local openVBoxRaw_exitStatus
	_open _waitVBox_opening _mountVBox_raw
	openVBoxRaw_exitStatus="$?"
	
	export specialLock=""
	
	return "$openVBoxRaw_exitStatus"
}

_closeVBoxRaw() {
	_findInfrastructure_virtImage ${FUNCNAME[0]} "$@"
	[[ "$ubVirtImageLocal" == "false" ]] && return
	
	export specialLock="$lock_open_vbox"
	
	if [[ "$1" == "--force" ]]
	then
		_close --force _waitVBox_closing _umountVBox_raw
		[[ "$1" != "" ]] && _tryExecFull _unhook_systemd_shutdown "$1"
		export specialLock=""
		return 0
	fi
	
	_close _waitVBox_closing _umountVBox_raw
	[[ "$1" != "" ]] && _tryExecFull _unhook_systemd_shutdown "$1"
	export specialLock=""
	return 0
}

##VBox Boxing
_wait_lab_vbox() {
	_prepare_lab_vbox || return 1
	
	VBoxXPCOMIPCD_PID=$(cat "$VBoxXPCOMIPCD_PIDfile" 2> /dev/null)
	#echo -e '\E[1;32;46mWaiting for VBoxXPCOMIPCD to finish... \E[0m'
	while kill -0 "$VBoxXPCOMIPCD_PID" > /dev/null 2>&1
	do
		sleep 0.2
	done
}

#Not routine.
_remove_lab_vbox() {
	_prepare_lab_vbox || return 1
	
	_wait_lab_vbox
	
	#echo -e '\E[1;32;46mRemoving IPC folder and vBoxHome directory symlink from filesystem.\E[0m'
	
	rm -f /tmp/\.vbox-"$VBOX_IPC_SOCKETID"-ipc/ipcd > /dev/null 2>&1
	rm -f /tmp/\.vbox-"$VBOX_IPC_SOCKETID"-ipc/lock > /dev/null 2>&1
	rmdir /tmp/\.vbox-"$VBOX_IPC_SOCKETID"-ipc > /dev/null 2>&1
	
	rm -f "$VBOX_USER_HOME_short" > /dev/null 2>&1
}


_launch_lab_vbox_sequence() {
	_start
	
	_prepare_lab_vbox || return 1
	
	#Directly opening raw images in the VBoxLab environment is not recommended, due to changing VMDK disk identifiers.
	#Better practice may be to instead programmatically construct the raw image virtual machines before opening VBoxLab environment.
	#_openVBoxRaw
	
	env HOME="$VBOX_USER_HOME_short" VirtualBox "$@"
	
	_wait_lab_vbox
	
	_stop
}

_launch_lab_vbox() {	
	"$scriptAbsoluteLocation" _launch_lab_vbox_sequence "$@"
}

_labVBox() {
	_launch_lab_vbox "$@"
}

_vboxlabSSH() {
	ssh -q -F "$scriptLocal"/vblssh -i "$scriptLocal"/id_rsa "$1"
}

_prepare_instance_vbox() {
	_prepare_vbox "$instancedVirtDir"
}

_wait_instance_vbox() {
	_prepare_instance_vbox || return 1
	
	VBoxXPCOMIPCD_PID=$(cat "$VBoxXPCOMIPCD_PIDfile" 2> /dev/null)
	#echo -e '\E[1;32;46mWaiting for VBoxXPCOMIPCD to finish... \E[0m'
	while kill -0 "$VBoxXPCOMIPCD_PID" > /dev/null 2>&1
	do
		sleep 0.2
	done
}

_rm_instance_vbox() {
	_prepare_instance_vbox || return 1
	
	#Usually unnecessary, possibly destructive, may delete VM images.
	#VBoxManage unregistervm "$sessionid" --delete > /dev/null 2>&1
	
	_safeRMR "$instancedVirtDir" || return 1
	
	rm -f /tmp/\.vbox-"$VBOX_IPC_SOCKETID"-ipc/ipcd > /dev/null 2>&1
	rm -f /tmp/\.vbox-"$VBOX_IPC_SOCKETID"-ipc/lock > /dev/null 2>&1
	rmdir /tmp/\.vbox-"$VBOX_IPC_SOCKETID"-ipc > /dev/null 2>&1
	
	rm -f "$VBOX_USER_HOME_short" > /dev/null 2>&1
	
	#_closeVBoxRaw || return 1
	
	return 0
}

#Not routine.
_remove_instance_vbox() {
	_prepare_instance_vbox || return 1
}

_vboxGUI() {
	#VirtualBox "$@"
	VBoxSDL "$@"
}


_set_instance_vbox_type() {
	#[[ "$vboxOStype" == "" ]] && export vboxOStype=Debian_64
	#[[ "$vboxOStype" == "" ]] && export vboxOStype=Gentoo
	#[[ "$vboxOStype" == "" ]] && export vboxOStype=Windows2003
	#[[ "$vboxOStype" == "" ]] && export vboxOStype=WindowsXP
	
	[[ "$vboxOStype" == "" ]] && _readLocked "$lock_open" && export vboxOStype=Debian_64
	[[ "$vboxOStype" == "" ]] && export vboxOStype=WindowsXP
	
	_messagePlain_probe 'vboxOStype= '"$vboxOStype"
	
	if VBoxManage createvm --name "$sessionid" --ostype "$vboxOStype" --register --basefolder "$VBOX_USER_HOME_short"
	then
		_messagePlain_probe VBoxManage createvm --name "$sessionid" --ostype "$vboxOStype" --register --basefolder "$VBOX_USER_HOME_short"
		return 0
	fi
	_messagePlain_bad 'fail: 'VBoxManage createvm --name "$sessionid" --ostype "$vboxOStype" --register --basefolder "$VBOX_USER_HOME_short"
	return 1
}

_set_instance_vbox_features() {
	#VBoxManage modifyvm "$sessionid" --boot1 disk --biosbootmenu disabled --bioslogofadein off --bioslogofadeout off --bioslogodisplaytime 5 --vram 128 --memory 1512 --nic1 nat --nictype1 "82543GC" --clipboard bidirectional --accelerate3d off --accelerate2dvideo off --vrde off --audio pulse --usb on --cpus 1 --ioapic off --acpi on --pae off --chipset piix3
	
	[[ "$vboxNic" == "" ]] && vboxNic="nat"
	_messagePlain_probe 'vboxNic= '"$vboxNic"
	
	local vboxChipset
	vboxChipset="ich9"
	#[[ "$vboxOStype" == *"Win"*"XP"* ]] && vboxChipset="piix3"
	_messagePlain_probe 'vboxChipset= '"$vboxChipset"
	
	local vboxNictype
	vboxNictype="82543GC"
	[[ "$vboxOStype" == *"Win"*"7"* ]] && vboxNictype="82540EM"
	[[ "$vboxOStype" == *"Win"*"10"* ]] && vboxNictype="82540EM"
	_messagePlain_probe 'vboxNictype= '"$vboxNictype"
	
	local vboxAudioController
	vboxAudioController="ac97"
	[[ "$vboxOStype" == *"Win"*"7"* ]] && vboxAudioController="hda"
	[[ "$vboxOStype" == *"Win"*"10"* ]] && vboxAudioController="hda"
	_messagePlain_probe 'vboxAudioController= '"$vboxAudioController"
	
	[[ "$vmMemoryAllocation" == "" ]] && vmMemoryAllocation="$vmMemoryAllocationDefault"
	_messagePlain_probe 'vmMemoryAllocation= '"$vmMemoryAllocation"
	
	_messagePlain_nominal "Setting VBox VM features."
	if ! VBoxManage modifyvm "$sessionid" --biosbootmenu disabled --bioslogofadein off --bioslogofadeout off --bioslogodisplaytime 1 --vram 128 --memory "$vmMemoryAllocation" --nic1 "$vboxNic" --nictype1 "$vboxNictype" --clipboard bidirectional --accelerate3d off --accelerate2dvideo off --vrde off --audio pulse --usb on --cpus 4 --ioapic on --acpi on --pae on --chipset "$vboxChipset" --audiocontroller="$vboxAudioController"
	then
		_messagePlain_probe VBoxManage modifyvm "$sessionid" --biosbootmenu disabled --bioslogofadein off --bioslogofadeout off --bioslogodisplaytime 1 --vram 128 --memory "$vmMemoryAllocation" --nic1 "$vboxNic" --nictype1 "$vboxNictype" --clipboard bidirectional --accelerate3d off --accelerate2dvideo off --vrde off --audio pulse --usb on --cpus 4 --ioapic on --acpi on --pae on --chipset "$vboxChipset" --audiocontroller="$vboxAudioController"
		_messagePlain_bad 'fail: VBoxManage'
		return 1
	fi
	return 0
	
}

_set_instance_vbox_share() {
	#VBoxManage sharedfolder add "$sessionid" --name "root" --hostpath "/"
	if [[ "$sharedHostProjectDir" != "" ]]
	then
		_messagePlain_probe VBoxManage sharedfolder add "$sessionid" --name "appFolder" --hostpath "$sharedHostProjectDir"
		
		! VBoxManage sharedfolder add "$sessionid" --name "appFolder" --hostpath "$sharedHostProjectDir" && _messagePlain_warn 'fail: mount sharedHostProjectDir= '"$sharedHostProjectDir"
	fi
	
	if [[ -e "$HOME"/Downloads ]]
	then
		_messagePlain_probe VBoxManage sharedfolder add "$sessionid" --name "Downloads" --hostpath "$HOME"/Downloads
		
		! VBoxManage sharedfolder add "$sessionid" --name "Downloads" --hostpath "$HOME"/Downloads && _messagePlain_warn 'fail: mount (shared) Downloads= '"$HOME"/Downloads
	fi
}

_set_instance_vbox_command() {
	_messagePlain_nominal 'Creating BootDisc.'
	! _commandBootdisc "$@" && _messagePlain_bad 'fail: _commandBootdisc' && return 1
	return 0
}

_create_instance_vbox() {
	
	#Use existing VDI image if available.
	if ! [[ -e "$scriptLocal"/vm.vdi ]]
	then
		_messagePlain_nominal 'Missing VDI. Attempting to create from IMG.'
		! _openVBoxRaw && _messageError 'FAIL' && return 1
	fi
	
	_messagePlain_nominal 'Checking VDI file.'
	export vboxInstanceDiskImage="$scriptLocal"/vm.vdi
	_readLocked "$lock_open" && vboxInstanceDiskImage="$vboxRaw"
	! [[ -e "$vboxInstanceDiskImage" ]] && _messagePlain_bad 'missing: vboxInstanceDiskImage= '"$vboxInstanceDiskImage" && return 1
	
	_messagePlain_nominal 'Determining OS type.'
	_set_instance_vbox_type
	
	! _set_instance_vbox_features && _messageError 'FAIL' && return 1
	
	_set_instance_vbox_command "$@"
	
	_messagePlain_nominal 'Mounting shared filesystems.'
	_set_instance_vbox_share
	
	_messagePlain_nominal 'Attaching local filesystems.'
	! VBoxManage storagectl "$sessionid" --name "IDE Controller" --add ide --controller PIIX4 && _messagePlain_bad 'fail: VBoxManage... attach ide controller'
	
	#export vboxDiskMtype="normal"
	[[ "$vboxDiskMtype" == "" ]] && export vboxDiskMtype="multiattach"
	_messagePlain_probe 'vboxDiskMtype= '"$vboxDiskMtype"
	
	_messagePlain_probe VBoxManage storageattach "$sessionid" --storagectl "IDE Controller" --port 0 --device 0 --type hdd --medium "$vboxInstanceDiskImage" --mtype "$vboxDiskMtype"
	! VBoxManage storageattach "$sessionid" --storagectl "IDE Controller" --port 0 --device 0 --type hdd --medium "$vboxInstanceDiskImage" --mtype "$vboxDiskMtype" && _messagePlain_bad 'fail: VBoxManage... attach vboxInstanceDiskImage= '"$vboxInstanceDiskImage"
	
	[[ -e "$hostToGuestISO" ]] && ! VBoxManage storageattach "$sessionid" --storagectl "IDE Controller" --port 1 --device 0 --type dvddrive --medium "$hostToGuestISO" && _messagePlain_bad 'fail: VBoxManage... attach hostToGuestISO= '"$hostToGuestISO"
	
	#VBoxManage showhdinfo "$scriptLocal"/vm.vdi

	#Suppress annoying warnings.
	! VBoxManage setextradata global GUI/SuppressMessages "remindAboutAutoCapture,remindAboutMouseIntegration,remindAboutMouseIntegrationOn,showRuntimeError.warning.HostAudioNotResponding,remindAboutGoingSeamless,remindAboutInputCapture,remindAboutGoingFullscreen,remindAboutMouseIntegrationOff,confirmGoingSeamless,confirmInputCapture,remindAboutPausedVMInput,confirmVMReset,confirmGoingFullscreen,remindAboutWrongColorDepth" && _messagePlain_warn 'fail: VBoxManage... suppress messages'
	
	
	
	return 0
}

#Create and launch temporary VM around persistent disk image.
_user_instance_vbox_sequence() {
	_messageNormal '_user_instance_vbox_sequence: start'
	_start
	
	_prepare_instance_vbox || _stop 1
	
	_messageNormal '_user_instance_vbox_sequence: Checking lock vBox_vdi= '"$vBox_vdi"
	_readLocked "$vBox_vdi" && _messagePlain_bad 'lock: vBox_vdi= '"$vBox_vdi" && _stop 1
	
	_messageNormal '_user_instance_vbox_sequence: Creating instance. '"$sessionid"
	if ! _create_instance_vbox "$@"
	then
		_stop 1
	fi
	
	_messageNormal '_user_instance_vbox_sequence: Launch: _vboxGUI '"$sessionid"
	 _vboxGUI --startvm "$sessionid"
	
	_messageNormal '_user_instance_vbox_sequence: Removing instance. '"$sessionid"
	_rm_instance_vbox
	
	_messageNormal '_user_instance_vbox_sequence: stop'
	_stop
}

_user_instance_vbox() {
	"$scriptAbsoluteLocation" _user_instance_vbox_sequence "$@"
}

_userVBox() {
	_findInfrastructure_virtImage ${FUNCNAME[0]} "$@"
	[[ "$ubVirtImageLocal" == "false" ]] && return
	
	_messageNormal 'Begin: '"$@"
	_user_instance_vbox "$@"
	_messageNormal 'End: '"$@"
}

_edit_instance_vbox_sequence() {
	_start
	
	_prepare_instance_vbox || return 1
	
	#VBoxManage modifymedium "$scriptLocal"/vm.vdi --type normal
	
	export vboxDiskMtype="normal"
	if ! _create_instance_vbox "$@"
	then
		return 1
	fi
	
	_readLocked "$vBox_vdi" && return 1
	
	_createLocked "$vBox_vdi" || return 1
	
	env HOME="$VBOX_USER_HOME_short" VirtualBox
	
	_wait_instance_vbox
	
	#VBoxManage modifymedium "$scriptLocal"/vm.vdi --type multiattach
	
	rm -f "$vBox_vdi" > /dev/null 2>&1
	
	_rm_instance_vbox
	
	_stop
}

_edit_instance_vbox() {
	"$scriptAbsoluteLocation" _edit_instance_vbox_sequence "$@"
}

_editVBox() {
	_findInfrastructure_virtImage ${FUNCNAME[0]} "$@"
	[[ "$ubVirtImageLocal" == "false" ]] && return
	
	_messageNormal 'Begin: '"$@"
	_edit_instance_vbox "$@"
	_messageNormal 'End: '"$@"
}


_here_dosbox_base_conf() {

cat << 'CZXWXcRMTo8EmM8i4d'
# This is the configurationfile for DOSBox 0.74. (Please use the latest version of DOSBox)
# Lines starting with a # are commentlines and are ignored by DOSBox.
# They are used to (briefly) document the effect of each option.

[sdl]
#       fullscreen: Start dosbox directly in fullscreen. (Press ALT-Enter to go back)
#       fulldouble: Use double buffering in fullscreen. It can reduce screen flickering, but it can also result in a slow DOSBox.
#   fullresolution: What resolution to use for fullscreen: original or fixed size (e.g. 1024x768).
#                     Using your monitor's native resolution with aspect=true might give the best results.
#                     If you end up with small window on a large screen, try an output different from surface.
# windowresolution: Scale the window to this size IF the output device supports hardware scaling.
#                     (output=surface does not!)
#           output: What video system to use for output.
#                   Possible values: surface, overlay, opengl, openglnb.
#         autolock: Mouse will automatically lock, if you click on the screen. (Press CTRL-F10 to unlock)
#      sensitivity: Mouse sensitivity.
#      waitonerror: Wait before closing the console if dosbox has an error.
#         priority: Priority levels for dosbox. Second entry behind the comma is for when dosbox is not focused/minimized.
#                     pause is only valid for the second entry.
#                   Possible values: lowest, lower, normal, higher, highest, pause.
#       mapperfile: File used to load/save the key/event mappings from. Resetmapper only works with the defaul value.
#     usescancodes: Avoid usage of symkeys, might not work on all operating systems.

fullscreen=false
fulldouble=false
fullresolution=original
windowresolution=original
output=surface
autolock=true
sensitivity=100
waitonerror=true
priority=higher,normal
mapperfile=mapper-0.74.map
usescancodes=true

[dosbox]
# language: Select another language file.
#  machine: The type of machine tries to emulate.
#           Possible values: hercules, cga, tandy, pcjr, ega, vgaonly, svga_s3, svga_et3000, svga_et4000, svga_paradise, vesa_nolfb, vesa_oldvbe.
# captures: Directory where things like wave, midi, screenshot get captured.
#  memsize: Amount of memory DOSBox has in megabytes.
#             This value is best left at its default to avoid problems with some games,
#             though few games might require a higher value.
#             There is generally no speed advantage when raising this value.

language=
machine=svga_s3
captures=capture
memsize=16

[render]
# frameskip: How many frames DOSBox skips before drawing one.
#    aspect: Do aspect correction, if your output method doesn't support scaling this can slow things down!.
#    scaler: Scaler used to enlarge/enhance low resolution modes.
#              If 'forced' is appended, then the scaler will be used even if the result might not be desired.
#            Possible values: none, normal2x, normal3x, advmame2x, advmame3x, advinterp2x, advinterp3x, hq2x, hq3x, 2xsai, super2xsai, supereagle, tv2x, tv3x, rgb2x, rgb3x, scan2x, scan3x.

frameskip=0
aspect=false
scaler=normal2x

[cpu]
#      core: CPU Core used in emulation. auto will switch to dynamic if available and appropriate.
#            Possible values: auto, dynamic, normal, simple.
#   cputype: CPU Type used in emulation. auto is the fastest choice.
#            Possible values: auto, 386, 386_slow, 486_slow, pentium_slow, 386_prefetch.
#    cycles: Amount of instructions DOSBox tries to emulate each millisecond.
#            Setting this value too high results in sound dropouts and lags.
#            Cycles can be set in 3 ways:
#              'auto'          tries to guess what a game needs.
#                              It usually works, but can fail for certain games.
#              'fixed #number' will set a fixed amount of cycles. This is what you usually need if 'auto' fails.
#                              (Example: fixed 4000).
#              'max'           will allocate as much cycles as your computer is able to handle.
#            
#            Possible values: auto, fixed, max.
#   cycleup: Amount of cycles to decrease/increase with keycombo.(CTRL-F11/CTRL-F12)
# cycledown: Setting it lower than 100 will be a percentage.

core=auto
cputype=auto
cycles=auto
cycleup=10
cycledown=20

[mixer]
#   nosound: Enable silent mode, sound is still emulated though.
#      rate: Mixer sample rate, setting any device's rate higher than this will probably lower their sound quality.
#            Possible values: 44100, 48000, 32000, 22050, 16000, 11025, 8000, 49716.
# blocksize: Mixer block size, larger blocks might help sound stuttering but sound will also be more lagged.
#            Possible values: 1024, 2048, 4096, 8192, 512, 256.
# prebuffer: How many milliseconds of data to keep on top of the blocksize.

nosound=false
rate=44100
blocksize=1024
prebuffer=20

[midi]
#     mpu401: Type of MPU-401 to emulate.
#             Possible values: intelligent, uart, none.
# mididevice: Device that will receive the MIDI data from MPU-401.
#             Possible values: default, win32, alsa, oss, coreaudio, coremidi, none.
# midiconfig: Special configuration options for the device driver. This is usually the id of the device you want to use.
#               See the README/Manual for more details.

mpu401=intelligent
mididevice=default
midiconfig=

[sblaster]
#  sbtype: Type of Soundblaster to emulate. gb is Gameblaster.
#          Possible values: sb1, sb2, sbpro1, sbpro2, sb16, gb, none.
#  sbbase: The IO address of the soundblaster.
#          Possible values: 220, 240, 260, 280, 2a0, 2c0, 2e0, 300.
#     irq: The IRQ number of the soundblaster.
#          Possible values: 7, 5, 3, 9, 10, 11, 12.
#     dma: The DMA number of the soundblaster.
#          Possible values: 1, 5, 0, 3, 6, 7.
#    hdma: The High DMA number of the soundblaster.
#          Possible values: 1, 5, 0, 3, 6, 7.
# sbmixer: Allow the soundblaster mixer to modify the DOSBox mixer.
# oplmode: Type of OPL emulation. On 'auto' the mode is determined by sblaster type. All OPL modes are Adlib-compatible, except for 'cms'.
#          Possible values: auto, cms, opl2, dualopl2, opl3, none.
#  oplemu: Provider for the OPL emulation. compat might provide better quality (see oplrate as well).
#          Possible values: default, compat, fast.
# oplrate: Sample rate of OPL music emulation. Use 49716 for highest quality (set the mixer rate accordingly).
#          Possible values: 44100, 49716, 48000, 32000, 22050, 16000, 11025, 8000.

sbtype=sb16
sbbase=220
irq=7
dma=1
hdma=5
sbmixer=true
oplmode=auto
oplemu=default
oplrate=44100

[gus]
#      gus: Enable the Gravis Ultrasound emulation.
#  gusrate: Sample rate of Ultrasound emulation.
#           Possible values: 44100, 48000, 32000, 22050, 16000, 11025, 8000, 49716.
#  gusbase: The IO base address of the Gravis Ultrasound.
#           Possible values: 240, 220, 260, 280, 2a0, 2c0, 2e0, 300.
#   gusirq: The IRQ number of the Gravis Ultrasound.
#           Possible values: 5, 3, 7, 9, 10, 11, 12.
#   gusdma: The DMA channel of the Gravis Ultrasound.
#           Possible values: 3, 0, 1, 5, 6, 7.
# ultradir: Path to Ultrasound directory. In this directory
#           there should be a MIDI directory that contains
#           the patch files for GUS playback. Patch sets used
#           with Timidity should work fine.

gus=false
gusrate=44100
gusbase=240
gusirq=5
gusdma=3
ultradir=C:\ULTRASND

[speaker]
# pcspeaker: Enable PC-Speaker emulation.
#    pcrate: Sample rate of the PC-Speaker sound generation.
#            Possible values: 44100, 48000, 32000, 22050, 16000, 11025, 8000, 49716.
#     tandy: Enable Tandy Sound System emulation. For 'auto', emulation is present only if machine is set to 'tandy'.
#            Possible values: auto, on, off.
# tandyrate: Sample rate of the Tandy 3-Voice generation.
#            Possible values: 44100, 48000, 32000, 22050, 16000, 11025, 8000, 49716.
#    disney: Enable Disney Sound Source emulation. (Covox Voice Master and Speech Thing compatible).

pcspeaker=true
pcrate=44100
tandy=auto
tandyrate=44100
disney=true

[joystick]
# joysticktype: Type of joystick to emulate: auto (default), none,
#               2axis (supports two joysticks),
#               4axis (supports one joystick, first joystick used),
#               4axis_2 (supports one joystick, second joystick used),
#               fcs (Thrustmaster), ch (CH Flightstick).
#               none disables joystick emulation.
#               auto chooses emulation depending on real joystick(s).
#               (Remember to reset dosbox's mapperfile if you saved it earlier)
#               Possible values: auto, 2axis, 4axis, 4axis_2, fcs, ch, none.
#        timed: enable timed intervals for axis. Experiment with this option, if your joystick drifts (away).
#     autofire: continuously fires as long as you keep the button pressed.
#       swap34: swap the 3rd and the 4th axis. can be useful for certain joysticks.
#   buttonwrap: enable button wrapping at the number of emulated buttons.

joysticktype=auto
timed=true
autofire=false
swap34=false
buttonwrap=false

[serial]
# serial1: set type of device connected to com port.
#          Can be disabled, dummy, modem, nullmodem, directserial.
#          Additional parameters must be in the same line in the form of
#          parameter:value. Parameter for all types is irq (optional).
#          for directserial: realport (required), rxdelay (optional).
#                           (realport:COM1 realport:ttyS0).
#          for modem: listenport (optional).
#          for nullmodem: server, rxdelay, txdelay, telnet, usedtr,
#                         transparent, port, inhsocket (all optional).
#          Example: serial1=modem listenport:5000
#          Possible values: dummy, disabled, modem, nullmodem, directserial.
# serial2: see serial1
#          Possible values: dummy, disabled, modem, nullmodem, directserial.
# serial3: see serial1
#          Possible values: dummy, disabled, modem, nullmodem, directserial.
# serial4: see serial1
#          Possible values: dummy, disabled, modem, nullmodem, directserial.

serial1=dummy
serial2=dummy
serial3=disabled
serial4=disabled

[dos]
#            xms: Enable XMS support.
#            ems: Enable EMS support.
#            umb: Enable UMB support.
# keyboardlayout: Language code of the keyboard layout (or none).

xms=true
ems=true
umb=true
keyboardlayout=auto

[ipx]
# ipx: Enable ipx over UDP/IP emulation.

ipx=false

[autoexec]
# Lines in this section will be run at startup.
# You can put your MOUNT lines here.

CZXWXcRMTo8EmM8i4d

}

_test_dosbox() {
	_getDep dosbox
	
	! _noFireJail dosbox && _stop 1
}

_prepare_dosbox() {
	mkdir -p "$scriptLocal"/_dosbox
	
	mkdir -p "$instancedVirtDir"
	mkdir -p "$instancedVirtFS"
	mkdir -p "$instancedVirtTmp"
	
	_here_dosbox_base_conf > "$instancedVirtDir"/dosbox.conf
	
}

_dosbox_sequence() {
	_start
	
	_prepare_dosbox
	
	echo -e -n 'mount c ' >> "$instancedVirtDir"/dosbox.conf
	echo "$scriptLocal"/_dosbox >> "$instancedVirtDir"/dosbox.conf
	echo 'c:' >> "$instancedVirtDir"/dosbox.conf
	
	export sharedGuestProjectDir='X:'
	_virtUser "$@"
	
	if [[ "$sharedHostProjectDir" != "" ]]
	then
		echo -e -n 'mount x ' >> "$instancedVirtDir"/dosbox.conf
		echo "$sharedHostProjectDir" >> "$instancedVirtDir"/dosbox.conf
		echo 'x:' >> "$instancedVirtDir"/dosbox.conf
	fi
	
	#Alternatively, "-c" could be used with dosbox, but this seems not to work well with multiple parameters.
	#Note "DOS" will not like paths not conforming to 8.3 .
	_safeEcho_newline "${processedArgs[@]}" >> "$instancedVirtDir"/dosbox.conf
	
	dosbox -conf "$instancedVirtDir"/dosbox.conf
	
	_safeRMR "$instancedVirtDir" || _stop 1
	
	_stop
}

_dosbox() {
	"$scriptAbsoluteLocation" _dosbox_sequence "$@"
}

_testWINE() {
	_getDep wine
	
	if wine 2>&1 | grep 'wine32 is missing' > /dev/null 2>&1
	then
		echo 'wine32 may be missing'
		_stop 1
	fi
	
	! _noFireJail wine && _stop 1
}

_setBottleDir() {
	export wineExeDir
	export wineBottle
	export WINEPREFIX
	
	export sharedHostProjectDir
	export sharedGuestProjectDir
	export processedArgs
	
	local wineAppDir
	local oldWineAppDir
	
	#wineExeDir=$(_searchBaseDir "$@" "$PWD")
	wineExeDir="$PWD"
	
	[[ -e "$1" ]] && [[ "$1" == *".exe" ]] && wineExeDir=$(_getAbsoluteFolder "$1")
	
	
	if uname -m | grep 64 > /dev/null 2>&1
	then
		wineAppDir=${wineExeDir/\/_wbottle*}
		wineBottle="$wineAppDir"/_wbottle
		
		#Optional support for older naming convention.
		#oldWineAppDir=${wineExeDir/\/wineBottle*}
		#[[ -e "$oldWineAppDir"/wineBottle ]] && wineBottle="$oldWineAppDir"/wineBottle
		
		[[ "$wineBottleHere" != "true" ]] && wineBottle="$scriptLocal"/_wbottle
	else
		wineAppDir=${wineExeDir/\/_wine32*}
		wineBottle="$wineAppDir"/_wine32
		
		[[ "$wineBottleHere" != "true" ]] && wineBottle="$scriptLocal"/_wine32
		
		export WINEARCH
		WINEARCH=win32
	fi
	
	mkdir -p "$wineBottle"
	
	export WINEPREFIX="$wineBottle"/
	
	sharedHostProjectDir=/
	sharedGuestProjectDir='Z:'
	
	_virtUser "$@"
	
}

_setBottleHere() {
	export wineBottleHere
	wineBottleHere="true"
}

_winecfghere() {
	_setBottleHere
	_setBottleDir "$@"
	
	winecfg
}

_winehere() {
	_setBottleHere
	_setBottleDir "$@"
	
	wine "${processedArgs[@]}"
}

_winecfg() {
	_setBottleDir "$@"
	
	winecfg
}

_wine() {
	_setBottleDir "$@"
	
	wine "${processedArgs[@]}"
}

#####Shortcuts

_visualPrompt() {
#+%H:%M:%S\ %Y-%m-%d\ Q%q
#+%H:%M:%S\ %b\ %d,\ %y
export PS1='\[\033[01;40m\]\[\033[01;36m\]+\[\033[01;34m\]-|\[\033[01;31m\]${?}:${debian_chroot:+($debian_chroot)}\[\033[01;33m\]\u\[\033[01;32m\]@\h\[\033[01;36m\]\[\033[01;34m\])-\[\033[01;36m\]------------------------\[\033[01;34m\]-(\[\033[01;35m\]$(date +%H:%M:%S\ .%d)\[\033[01;34m\])-\[\033[01;36m\]- -|\[\033[00m\]\n\[\033[01;40m\]\[\033[01;36m\]+\[\033[01;34m\]-|\[\033[37m\][\w]\[\033[00m\]\n\[\033[01;36m\]+\[\033[01;34m\]-|\#) \[\033[36m\]>\[\033[00m\] '
} 

#https://stackoverflow.com/questions/15432156/display-filename-before-matching-line-grep
_grepFileLine() {
	grep -n "$@" /dev/null
}

_findFunction() {
	#-name '*.sh'
	#-not -path "./_local/*"
	#find ./blockchain -name '*.sh' -type f -size -10000k -exec grep -n "$@" {} /dev/null \;
	#find ./generic -name '*.sh' -type f -size -10000k -exec grep -n "$@" {} /dev/null \;
	#find ./instrumentation -name '*.sh' -type f -size -10000k -exec grep -n "$@" {} /dev/null \;
	#find ./labels -name '*.sh' -type f -size -10000k -exec grep -n "$@" {} /dev/null \;
	#find ./os -name '*.sh' -type f -size -10000k -exec grep -n "$@" {} /dev/null \;
	#find ./shortcuts -name '*.sh' -type f -size -10000k -exec grep -n "$@" {} /dev/null \;
	#find . -name '*.sh' -type f -size -10000k -exec grep -n "$@" {} /dev/null \;
	
	find . -not -path "./_local/*" -name '*.sh' -type f -size -1000k -exec grep -n "$@" {} /dev/null \;
}

_test_devemacs() {
	_getDep emacs
	
	local emacsDetectedVersion=$(emacs --version | head -n 1 | cut -f 3 -d\ | cut -d\. -f1)
	! [[ "$emacsDetectedVersion" -ge "24" ]] && echo emacs too old && _stop 1
}

_set_emacsFakeHomeSource() {
	if [[ ! -e "$scriptLib"/app/emacs/home ]]
	then
		_messageError 'missing: '"$scriptLib"'/app/emacs/home'
		_messageFAIL
		_stop 1
	fi
	
	export emacsFakeHomeSource="$scriptLib"/app/emacs/home
	if ! [[ -e "$emacsFakeHomeSource" ]]
	then
		export emacsFakeHomeSource="$scriptLib"/ubiquitous_bash/_lib/app/emacs/home
	fi
}

_install_fakeHome_emacs() {
	_link_fakeHome "$emacsFakeHomeSource"/.emacs .emacs
	_link_fakeHome "$emacsFakeHomeSource"/.emacs.d .emacs.d
}

_emacs_edit_procedure() {
	_set_emacsFakeHomeSource
	
	export actualFakeHome="$instancedFakeHome"
	#export actualFakeHome="$globalFakeHome"
	export fakeHomeEditLib="true"
	export keepFakeHome="false"
	
	_install_fakeHome_emacs
	
	#echo -n "$@" >> "$HOME"/.emacs
	
	_fakeHome emacs "$@"
}

_emacs_edit_sequence() {
	_start
	
	_emacs_edit_procedure "$@"
	
	_stop $?
}

_emacs_edit() {
	"$scriptAbsoluteLocation" _emacs_edit_sequence "$@"
}

_emacs_user_procedure() {
	_set_emacsFakeHomeSource
	
	export actualFakeHome="$instancedFakeHome"
	#export actualFakeHome="$globalFakeHome"
	export fakeHomeEditLib="false"
	export keepFakeHome="false"
	
	_install_fakeHome_emacs
	
	#echo -n "$@" >> "$HOME"/.emacs
	
	_fakeHome emacs "$@"
}

_emacs_user_sequence() {
	_start
	
	_emacs_user_procedure "$@"
	
	_stop $?
}

_emacs_user() {
	"$scriptAbsoluteLocation" _emacs_user_sequence "$@"
}

_emacs() {
	_emacs_user "$@"
}

_bashdb_procedure() {
	_set_emacsFakeHomeSource
	
	export actualFakeHome="$instancedFakeHome"
	export fakeHomeEditLib="false"
	export keepFakeHome="false"
	
	_install_fakeHome_emacs
	
	#echo -n '(bashdb "bash --debugger' >> "$actualFakeHome"/.emacs
	echo -n '(bashdb-large "bash --debugger' >> "$actualFakeHome"/.emacs
	
	local currentArg
	
	for currentArg in "$@"
	do
		echo -n ' ' >> "$actualFakeHome"/.emacs
		echo -n '\"' >> "$actualFakeHome"/.emacs
		echo -n "$currentArg" >> "$actualFakeHome"/.emacs
		echo -n '\"' >> "$actualFakeHome"/.emacs
	done
	
	echo '")' >> "$actualFakeHome"/.emacs
	
	_fakeHome emacs
}

_bashdb_sequence() {
	_start
	
	_bashdb_procedure "$@"
	
	_stop $?
}

_bashdb() {
	"$scriptAbsoluteLocation" _bashdb_sequence "$@"
}

_ubdb() {
	_bashdb "$scriptAbsoluteLocation" "$@"
}

_test_devatom() {
	_getDep rsync
	
	_getDep atom
	
	#local atomDetectedVersion=$(atom --version | head -n 1 | cut -f 2- -d \: | cut -f 2- -d \  | cut -f 2 -d \. )
	#! [[ "$atomDetectedVersion" -ge "27" ]] && echo atom too old && _stop 1
}

_install_fakeHome_atom() {	
	_link_fakeHome "$atomFakeHomeSource"/.atom .atom
	
	_link_fakeHome "$atomFakeHomeSource"/.config/Atom .config/Atom
}

_set_atomFakeHomeSource() {
	export atomFakeHomeSource="$scriptLib"/app/atom/home
	
	if ! [[ -e "$atomFakeHomeSource" ]]
	then
		true
		#export atomFakeHomeSource="$scriptLib"/ubiquitous_bash/_lib/app/atom/home
	fi
	
	if [[ ! -e "$scriptLib"/app/atom/home ]]
	then
		_messageError 'missing: atomFakeHomeSource= '"$atomFakeHomeSource" > /dev/tty
		_messageFAIL
		_stop 1
	fi
}

_atom_user_procedure() {
	_set_atomFakeHomeSource
	
	export actualFakeHome="$instancedFakeHome"
	#export actualFakeHome="$globalFakeHome"
	export fakeHomeEditLib="false"
	export keepFakeHome="true"
	
	_install_fakeHome_atom
	
	_fakeHome atom --foreground "$@"
}

_atom_user_sequence() {
	_start
	
	"$scriptAbsoluteLocation" _atom_user_procedure "$@"
	
	_stop $?
}

_atom_user() {
	_atom_user_sequence "$@"  > /dev/null 2>&1 &
}

_atom_edit_procedure() {
	_set_atomFakeHomeSource
	
	export actualFakeHome="$instancedFakeHome"
	#export actualFakeHome="$globalFakeHome"
	export fakeHomeEditLib="true"
	export keepFakeHome="true"
	
	_install_fakeHome_atom
	
	_fakeHome atom --foreground "$@"
}

_atom_edit_sequence() {
	_start
	
	_atom_edit_procedure "$@"
	
	_stop $?
}

_atom_edit() {
	"$scriptAbsoluteLocation" _atom_edit_sequence "$@"  > /dev/null 2>&1 &
}

_atom_config() {
	_set_atomFakeHomeSource
	
	export ATOM_HOME="$atomFakeHomeSource"/.atom
	atom "$@"
}

_atom_tmp_procedure() {
	_set_atomFakeHomeSource
	
	mkdir -p "$safeTmp"/atom
	
	rsync -q -ax --exclude "/.cache" "$atomFakeHomeSource"/.atom/ "$safeTmp"/atom/
	
	export ATOM_HOME="$safeTmp"/atom
	atom --foreground "$@"
	unset ATOM_HOME
}

_atom_tmp_sequence() {
	_start
	
	_atom_tmp_procedure "$@"
	
	_stop $?
}

_atom_tmp() {
	"$scriptAbsoluteLocation" _atom_tmp_sequence "$@"  > /dev/null 2>&1 &
}

_atom() {
	_atom_tmp "$@"
}

_ubide() {
	_atom . ./ubiquitous_bash.sh "$@"
}

_test_deveclipse() {
	_getDep eclipse
	
	! [[ -e /usr/share/eclipse/dropins/cdt ]] && echo 'warn: missing: /usr/share/eclipse/dropins/cdt'
}

#"$1" == workspaceDir
_prepare_eclipse_workspace() {
	local local_workspace_import="$1"/_import
	
	mkdir -p "$local_workspace_import"
	
	local local_workspace_abstract
	
	#Scope
	if [[ "$ub_specimen" != "" ]] && [[ "$ub_scope" != "" ]]
	then
		local_workspace_abstract=$(_name_abstractfs "$ub_specimen")
		
		mkdir -p "$local_workspace_import"/"$local_workspace_abstract"
		
		_relink "$ub_specimen" "$local_workspace_import"/"$local_workspace_abstract"/specimen
		_relink "$ub_scope" "$local_workspace_import"/"$local_workspace_abstract"/scope
		
		#Export directories to be used for projects/sets to be stored in shared repositories.
		mkdir -p "$ub_specimen"/_export
		_relink "$ub_specimen"/_export "$local_workspace_import"/"$local_workspace_abstract"/_export
		
		_messagePlain_good 'eclipse: install: specimen, scope: '"$local_workspace_import"/"$local_workspace_abstract"
	fi
	
	#Arbitary Project
	if [[ "$arbitraryProjectDir" != "" ]]
	then
		local_workspace_abstract=$(_name_abstractfs "$arbitraryProjectDir")
		
		mkdir -p "$local_workspace_import"/"$local_workspace_abstract"
		
		_relink "$arbitraryProjectDir" "$local_workspace_import"/"$local_workspace_abstract"
		
		#Export directories to be used for projects/sets to be stored in shared repositories.
		mkdir -p "$arbitraryProjectDir"/_export
		_relink "$arbitraryProjectDir"/_export "$local_workspace_import"/"$local_workspace_abstract"/_export
		
		_messagePlain_good 'eclipse: install: arbitraryProjectDir: '"$local_workspace_import"/"$local_workspace_abstract"
	fi
}

#Creates user and export directories for eclipse instance. User directories to be used for project specific workspace. Export directories to be used for projects/sets to be stored in shared repositories.
#"$eclipse_path" (eg. "$ub_specimen")
#"eclipse_root" (eg. ".eclipser")
_prepare_eclipse() {
	#Special meaning of "$PWD" when run under _abstractfs ("$localPWD") is intended.
	if [[ "$eclipse_path" == "" ]]
	then
		export eclipse_path=$(_getAbsoluteLocation "$PWD"/..)
		[[ "$ub_specimen" != "" ]] && export eclipse_path=$(_getAbsoluteLocation "$ub_specimen"/..)
		#[[ "$ub_scope" != "" ]] && export eclipse_path=$(_getAbsoluteLocation "$ub_scope")
	fi
	
	if [[ "$eclipse_root" == "" ]]
	then
		export eclipse_root=$(_name_abstractfs "$ub_specimen")
		export eclipse_root="$eclipse_root".ecr
		#export eclipse_root='eclipser'
		#export eclipse_root='.eclipser'
	fi
	
	export eclipse_user='user'
	
	#export eclipse_export='_export'
	
	export eclipse_data='workspace'
	export eclipse_config='configuration'
	
	mkdir -p "$eclipse_path"/"$eclipse_root"
	mkdir -p "$eclipse_path"/"$eclipse_root"/"$eclipse_user"
	#mkdir -p "$eclipse_path"/"$eclipse_root"/"$eclipse_export"
	mkdir -p "$eclipse_path"/"$eclipse_root"/"$eclipse_data"
	mkdir -p "$eclipse_path"/"$eclipse_root"/"$eclipse_user"/"$eclipse_config"
	
	#_mustcarry 'eclipser/' "$eclipse_path"/"$eclipse_root"/.gitignore
	_mustcarry "$eclipse_user"/ "$eclipse_path"/"$eclipse_root"/.gitignore
	_mustcarry "$eclipse_data"/ "$eclipse_path"/"$eclipse_root"/.gitignore
	_mustcarry "$eclipse_user"/"$eclipse_config"/ "$eclipse_path"/"$eclipse_root"/.gitignore
}

_install_fakeHome_eclipse() {	
	_link_fakeHome "$eclipse_path"/"$eclipse_root"/"$eclipse_data" workspace
	
	_link_fakeHome "$eclipse_path"/"$eclipse_root"/"$eclipse_user" .eclipse
	#_link_fakeHome "$eclipse_path"/"$eclipse_root"/"$eclipse_user"/"$eclipse_config" .eclipse/configuration
}

_eclipse_procedure() {
	_prepare_eclipse
	_prepare_eclipse_workspace "$eclipse_path"/"$eclipse_root"/"$eclipse_data"
	_messagePlain_probe eclipse -data "$eclipse_path"/"$eclipse_root"/"$eclipse_data" -configuration "$eclipse_path"/"$eclipse_root"/"$eclipse_user"/"$eclipse_config" "$@"
	eclipse -data "$eclipse_path"/"$eclipse_root"/"$eclipse_data" -configuration "$eclipse_path"/"$eclipse_root"/"$eclipse_user"/"$eclipse_config" "$@"
}

_eclipse_config() {
	_eclipse_procedure "$@"
}

_eclipse_stock() {
	_prepare_eclipse_workspace "$HOME"/workspace
	eclipse -data "$HOME"/workspace "$@"
}

_eclipse_home() {
	_prepare_eclipse_workspace "$HOME"/workspace
	_messagePlain_probe eclipse -data "$HOME"/workspace -configuration "$HOME"/.eclipse/configuration "$@"
	eclipse -data "$HOME"/workspace -configuration "$HOME"/.eclipse/configuration "$@"
}

_eclipse_edit() {
	_prepare_eclipse
	
	export actualFakeHome="$shortFakeHome"
	#export actualFakeHome="$globalFakeHome"
	export fakeHomeEditLib="true"
	export keepFakeHome="true"
	
	_install_fakeHome_eclipse
	
	_fakeHome "$scriptAbsoluteLocation" --parent _eclipse_home "$@"
}

_eclipse_user() {
	_prepare_eclipse
	
	export actualFakeHome="$shortFakeHome"
	#export actualFakeHome="$globalFakeHome"
	export fakeHomeEditLib="false"
	export keepFakeHome="true"
	
	_install_fakeHome_eclipse
	
	_fakeHome "$scriptAbsoluteLocation" --parent _eclipse_home "$@"
}





_eclipse() {
	_eclipse_config "$@"
}

#Example, override with "core.sh" .
_scope_compile() {
	true
}

#Example, override with "core.sh" .
_scope_attach() {
	_messagePlain_nominal '_scope_attach'
	
	_scope_here > "$ub_scope"/.devenv
	chmod u+x "$ub_scope"/.devenv
	_scope_readme_here > "$ub_scope"/README
	
	_scope_command_write _scope_terminal_procedure
	
	_scope_command_write _scope_konsole_procedure
	_scope_command_write _scope_dolphin_procedure
	_scope_command_write _scope_eclipse_procedure
	_scope_command_write _scope_atom_procedure
	
	_scope_command_write _compile
	#_scope_command_external_here _compile
}

_prepare_scope() {
	#mkdir -p "$safeTmp"/scope
	mkdir -p "$scopeTmp"
	#true
}

_relink_scope() {
	#_relink "$safeTmp"/scope "$ub_scope"
	_relink "$scopeTmp" "$ub_scope"
	#_relink "$safeTmp" "$ub_scope"
	
	_relink "$safeTmp" "$ub_scope"/safeTmp
	_relink "$shortTmp" "$ub_scope"/shortTmp
	
	# DANGER: Creates infinitely recursive symlinks.
	#[[ -e "$abstractfs_projectafs" ]] && _relink "$abstractfs_projectafs" "$ub_scope"/project.afs
	#[[ -d "$abstractfs" ]] && _relink "$abstractfs" "$ub_scope"/afs
}

_ops_scope() {
	_messagePlain_nominal '_ops_scope'
	
	#Find/run ops file in project dir.
	! [[ -e "$ub_specimen"/ops ]] && _messagePlain_warn 'aU: undef: sketch ops'
	[[ -e "$ub_specimen"/ops ]] && _messagePlain_good 'aU: found: sketch ops' && . "$ub_specimen"/ops
}

#"$1" == ub_specimen
#"$ub_scope_name" (default "scope")
# WARNING Multiple instances of same scope on a single specimen strictly forbidden. Launch multiple applications within a scope, not multiple scopes.
_start_scope() {
	_messagePlain_nominal '_start_scope'
	
	export ub_specimen=$(_getAbsoluteLocation "$1")
	export specimen="$ub_specimen"
	export ub_specimen_basename=$(basename "$ub_specimen")
	export basename="$ub_specimen_basename"
	[[ ! -d "$ub_specimen" ]] && _messagePlain_bad 'missing: specimen= '"$ub_specimen" && _stop 1
	[[ ! -e "$ub_specimen" ]] && _messagePlain_bad 'missing: specimen= '"$ub_specimen" && _stop 1
	
	[[ "$ub_scope_name" == "" ]] && export ub_scope_name='scope'
	
	export ub_scope="$ub_specimen"/.s_"$ub_scope_name"
	export scope="$ub_scope"
	[[ -e "$ub_scope" ]] && _messagePlain_bad 'fail: safety: multiple scopes && single specimen' && _stop 1
	[[ -L "$ub_scope" ]] && _messagePlain_bad 'fail: safety: multiple scopes && single specimen' && _stop 1
	
	#export ub_scope_tmp="$ub_scope"/s_"$sessionid"
	
	_prepare_scope "$@"
	_relink_scope "$@"
	[[ ! -d "$ub_scope" ]] && _messagePlain_bad 'fail: link scope= '"$ub_scope" && _stop 1
	#[[ ! -d "$ub_scope_tmp" ]] && _messagePlain_bad 'fail: create ub_scope_tmp= '"$ub_scope_tmp" && _stop 1
	[[ ! -d "$ub_scope"/safeTmp ]] && _messagePlain_bad 'fail: link' && _stop 1
	[[ ! -d "$ub_scope"/shortTmp ]] && _messagePlain_bad 'fail: link' && _stop 1
	
	[[ ! -e "$ub_scope"/.pid ]] && echo $$ > "$ub_scope"/.pid
	
	_messagePlain_good 'pass: prepare, relink'
	
	return 0
}

#Defaults, bash terminal, wait for kill signal, wait for EOF, etc. Override with "core.sh" . May run file manager, terminal, etc.
# WARNING: Scope should only be terminated by process or user managing this interaction (eg. by closing file manager). Manager must be aware of any inter-scope dependencies.
#"$@" <commands>
_scope_interact() {
	_messagePlain_nominal '_scope_interact'
	#read > /dev/null 2>&1
	
	_scopePrompt
	
	if [[ "$@" == "" ]]
	then
		_scope_terminal_procedure
		#_scope_eclipse_procedure
		#eclipse
# 		return
	fi
	
	"$@"
}


_scope_sequence() {
	_messagePlain_nominal 'init: scope: '"$ub_scope_name"
	_messagePlain_probe 'HOME= '"$HOME"
	
	_start
	_start_scope "$@"
	_ops_scope
	
	_scope_attach "$@"
	
	#User interaction.
	shift
	_scope_interact "$@"
	
	_stop
}

# ATTENTION: Overload with "core.sh" or similar!
_scope_prog() {
	[[ "$ub_scope_name" == "" ]] && export ub_scope_name='scope'
}

_scope() {
	_scope_prog
	[[ "$ub_scope_name" == "" ]] && export ub_scope_name='scope'
	"$scriptAbsoluteLocation" _scope_sequence "$@"
}

_scope_readme_here() {
	cat << CZXWXcRMTo8EmM8i4d
Ubiquitous Bash scope.
CZXWXcRMTo8EmM8i4d
}

#Example, override with "core.sh" .
_scope_var_here_prog() {
	cat << CZXWXcRMTo8EmM8i4d
CZXWXcRMTo8EmM8i4d
}

_scope_var_here() {
	cat << CZXWXcRMTo8EmM8i4d
export ub_specimen="$ub_specimen"
export specimen="$specimen"
export ub_specimen_basename="$ub_specimen_basename"
export basename="$basename"
export ub_scope_name="$ub_scope_name"
export ub_scope="$ub_scope"
export scope="$scope"

CZXWXcRMTo8EmM8i4d
	
	_scope_var_here_prog "$@"
}

_scope_here() {
	cat << CZXWXcRMTo8EmM8i4d
#!/usr/bin/env bash

CZXWXcRMTo8EmM8i4d

	_scope_var_here

	cat << CZXWXcRMTo8EmM8i4d

export scriptAbsoluteLocation="$scriptAbsoluteLocation"
export scriptAbsoluteFolder="$scriptAbsoluteFolder"
export sessionid="$sessionid"
. "$scriptAbsoluteLocation" --devenv "\$@"
CZXWXcRMTo8EmM8i4d
}

_scope_command_here() {
	cat << CZXWXcRMTo8EmM8i4d
#!/usr/bin/env bash

CZXWXcRMTo8EmM8i4d

	_scope_var_here

	cat << CZXWXcRMTo8EmM8i4d

export scriptAbsoluteLocation="$scriptAbsoluteLocation"
export scriptAbsoluteFolder="$scriptAbsoluteFolder"
export sessionid="$sessionid"
. "$scriptAbsoluteLocation" --devenv "$1" "\$@"
CZXWXcRMTo8EmM8i4d
}

_scope_command_external_here() {
	cat << CZXWXcRMTo8EmM8i4d
#!/usr/bin/env bash

CZXWXcRMTo8EmM8i4d

	_scope_var_here

	cat << CZXWXcRMTo8EmM8i4d

export importScriptLocation="$scriptAbsoluteLocation"
export importScriptFolder="$scriptAbsoluteFolder"
. "$scriptAbsoluteLocation" --script "$1" "\$@"
CZXWXcRMTo8EmM8i4d
}

_scope_command_write() {
	_scope_command_here "$@" > "$ub_scope"/"$1"
	chmod u+x "$ub_scope"/"$1"
}

_scope_command_external_write() {
	_scope_command_external_here "$@" > "$ub_scope"/"$1"
	chmod u+x "$ub_scope"/"$1"
}

_scopePrompt() {
	[[ "$ub_scope_name" == "" ]] && return 0
	
	export PS1='\[\033[01;40m\]\[\033[01;36m\]+\[\033[01;34m\]-|\[\033[01;31m\]${?}:${debian_chroot:+($debian_chroot)}\[\033[01;33m\]\u\[\033[01;32m\]@\h\[\033[01;36m\]\[\033[01;34m\])-\[\033[01;36m\]------------------------\[\033[01;34m\]-(\[\033[01;35m\]$(date +%H:%M:%S\ .%d)\[\033[01;34m\])-\[\033[01;36m\]- -|\[\033[00m\]\n\[\033[01;40m\]\[\033[01;36m\]+\[\033[01;34m\]-|\[\033[37m\][\w]\[\033[00m\]\n\[\033[01;36m\]+\[\033[01;34m\]-|\#) \[\033[36m\]'"$ub_scope_name"'>\[\033[00m\] '
}

_scope_terminal_procedure() {
	_tryExec '_scopePrompt'
	#_tryExec '_visualPrompt'
	
	export PATH="$PATH":"$ub_scope"
	echo
	/bin/bash --norc
	echo
}

_scope_terminal() {
	local shiftParam1
	shiftParam1="$1"
	shift
	
	_scope_prog "$@"
	_scope "$shiftParam1" "_scope_terminal_procedure" "$@"
}

_scope_eclipse_procedure() {
	_eclipse "$@"
}

_scope_eclipse() {
	local shiftParam1
	shiftParam1="$1"
	shift
	
	_scope_prog "$@"
	_scope "$shiftParam1" "_scope_eclipse_procedure" "$@"
}

_scope_atom_procedure() {
	"$scriptAbsoluteLocation" _atom_tmp_sequence "$ub_specimen" "$@"  > /dev/null 2>&1
}

# WARNING: No production use. Not to be relied upon. May be removed.
_scope_atom() {
	local shiftParam1
	shiftParam1="$1"
	shift
	
	_scope_prog "$@"
	_scope "$shiftParam1" "_scope_atom_procedure" "$@"
}

_scope_konsole_procedure() {
	_messagePlain_probe konsole --workdir "$ub_specimen" "$@"
	konsole --workdir "$ub_specimen" "$@"
}

_scope_konsole() {
	local shiftParam1
	shiftParam1="$1"
	shift
	
	_scope_prog "$@"
	_scope "$shiftParam1" "_scope_konsole_procedure" -p tabtitle="$ub_scope_name" "$@"
}

_scope_dolphin_procedure() {
	dolphin "$ub_specimen" "$@"
}

_scope_dolphin() {
	local shiftParam1
	shiftParam1="$1"
	shift
	
	_scope_prog "$@"
	_scope "$shiftParam1" "_scope_dolphin_procedure" "$@"
}

_testGit() {
	_getDep git
}

#Ignores file modes, suitable for use with possibly broken filesystems like NTFS.
_gitCompatible() {
	git -c core.fileMode=false "$@"
}

_gitInfo() {
	#Git Repository Information
	export repoDir="$PWD"

	export repoName=$(basename "$repoDir")
	export bareRepoDir=../."$repoName".git
	export bareRepoAbsoluteDir=$(_getAbsoluteLocation "$bareRepoDir")

	#Set $repoHostName in user ".bashrc" or similar. May also set $repoPort including colon prefix.
	[[ "$repoHostname" == "" ]] && export repoHostname=$(hostname -f)
	
	true
}

_gitRemote() {
	_gitInfo
	
	if [[ -e "$bareRepoDir" ]]
	then
		_showGitRepoURI
		return 0
	fi
	
	if ! [[ -e "$repoDir"/.git ]]
	then
		return 1
	fi
	
	if git config --get remote.origin.url > /dev/null 2>&1
	then
		echo -n "git clone --recursive "
		git config --get remote.origin.url
		return 0
	fi
	_gitBare
}

_gitNew() {
	git init
	git add .
	git commit -a -m "first commit"
}

_gitImport() {
	cd "$scriptFolder"
	
	mkdir -p "$1"
	cd "$1"
	shift
	git clone "$@"
	
	cd "$scriptFolder"
}

_findGit_procedure() {
	cd "$1"
	shift
	
	if [[ -e "./.git" ]]
	then
		"$@"
		return 0
	fi
	
	find -L . -mindepth 1 -maxdepth 1 -type d -exec "$scriptAbsoluteLocation" _findGit_procedure {} "$@" \;
}

#Recursively searches for directories containing ".git".
_findGit() {
	if [[ -e "./.git" ]]
	then
		"$@"
		return 0
	fi
	
	find -L . -mindepth 1 -maxdepth 1 -type d -exec "$scriptAbsoluteLocation" _findGit_procedure {} "$@" \;
}

_gitPull() {
	git pull
	git submodule update --recursive
}

_gitCheck_sequence() {
	echo '-----'
	
	local checkRealpath
	checkRealpath=$(realpath .)
	local checkBasename
	checkBasename=$(basename "$checkRealpath")
	
	echo "$checkBasename"
	
	git status
}

_gitCheck() {
	_findGit "$scriptAbsoluteLocation" _gitCheck_sequence
}

_gitPullRecursive_sequence() {
	echo '-----'
	
	local checkRealpath
	checkRealpath=$(realpath .)
	local checkBasename
	checkBasename=$(basename "$checkRealpath")
	
	echo "$checkBasename"
	
	"$scriptAbsoluteLocation" _gitPull
}

# DANGER
#Updates all git repositories recursively.
_gitPullRecursive() {
	_findGit "$scriptAbsoluteLocation" _gitPullRecursive_sequence
}

# DANGER
#Removes all but the .git folder from the working directory.
#_gitFresh() {
#	find . -not -path '\.\/\.git*' -delete
#}


#####Program

_createBareGitRepo() {
	mkdir -p "$bareRepoDir"
	cd $bareRepoDir
	
	git --bare init
	
	echo "-----"
}


_setBareGitRepo() {
	cd "$repoDir"
	
	git remote rm origin
	git remote add origin "$bareRepoDir"
	git push --set-upstream origin master
	
	echo "-----"
}

_showGitRepoURI() {
	echo git clone --recursive ssh://"$USER"@"$repoHostname""$repoPort""$bareRepoAbsoluteDir" "$repoName"
	
	
	#if [[ "$repoHostname" != "" ]]
	#then
	#	clear
	#	echo ssh://"$USER"@"$repoHostname""$repoPort""$bareRepoAbsoluteDir"
	#	sleep 15
	#fi
}

_gitBareSequence() {
	_gitInfo
	
	if [[ -e "$bareRepoDir" ]]
	then
		_showGitRepoURI
		return 2
	fi
	
	if ! [[ -e "$repoDir"/.git ]]
	then
		return 1
	fi
	
	_createBareGitRepo
	
	_setBareGitRepo
	
	_showGitRepoURI
	
}

_gitBare() {
	
	"$scriptAbsoluteLocation" _gitBareSequence
	
}



_test_bup() {
	! _wantDep bup && echo 'warn: no bup'
	
	! man tar | grep '\-\-one-file-system' > /dev/null 2>&1 && echo 'warn: tar does not support one-file-system' && return 1
	! man tar | grep '\-\-xattrs' > /dev/null 2>&1 && echo 'warn: tar does not support xattrs'
	! man tar | grep '\-\-acls' > /dev/null 2>&1 && echo 'warn: tar does not support acls'
}

_bupNew() {
	export BUP_DIR="./.bup"
	
	[[ -e "$BUP_DIR" ]] && return 1
	
	bup init
}

_bupLog() {
	export BUP_DIR="./.bup"
	
	[[ ! -e "$BUP_DIR" ]] && return 1
	
	git --git-dir=./.bup log
}

_bupList() {
	export BUP_DIR="./.bup"
	
	[[ ! -e "$BUP_DIR" ]] && return 1
	
	if [[ "$1" == "" ]]
	then
		bup ls "HEAD"
		return
	fi
	[[ "$1" != "" ]] && bup ls "$@"
}

_bupStore() {
	export BUP_DIR="./.bup"
	
	[[ ! -e "$BUP_DIR" ]] && return 1
	
	! man tar | grep '\-\-one-file-system' > /dev/null 2>&1 && return 1
	! man tar | grep '\-\-xattrs' > /dev/null 2>&1 && return 1
	! man tar | grep '\-\-acls' > /dev/null 2>&1 && return 1
	
	if [[ "$1" == "" ]]
	then
		tar --one-file-system --xattrs --acls --exclude "$BUP_DIR" -cvf - . | bup split -n "HEAD" -vv
		return
	fi
	[[ "$1" != "" ]] && tar --one-file-system --xattrs --acls --exclude "$BUP_DIR" -cvf - . | bup split -n "$@" -vv
}

_bupRetrieve() {
	export BUP_DIR="./.bup"
	
	[[ ! -e "$BUP_DIR" ]] && return 1
	
	! man tar | grep '\-\-one-file-system' > /dev/null 2>&1 && return 1
	! man tar | grep '\-\-xattrs' > /dev/null 2>&1 && return 1
	! man tar | grep '\-\-acls' > /dev/null 2>&1 && return 1
	
	if [[ "$1" == "" ]]
	then
		bup join "HEAD" | tar --one-file-system --xattrs --acls -xf -
		return
	fi
	[[ "$1" != "" ]] && bup join "$@" | tar --one-file-system --xattrs --acls -xf -
}

_here_mkboot_grubcfg() {
	
	cat << 'CZXWXcRMTo8EmM8i4d'
set default="0"
set timeout="1"

menuentry "Buildroot" {
    insmod gzio
    insmod part_msdos
    insmod ext2
CZXWXcRMTo8EmM8i4d

	local linuxImageName
	linuxImageName=$(ls "$chrootDir"/boot | grep vmlinuz | tail -n 1)
	local linuxInitRamFS
	linuxInitRamFS=$(ls "$chrootDir"/boot | grep initrd | tail -n 1)
	
	echo "linux (hd0,msdos1)/boot/""$linuxImageName"" root=/dev/sda1 rw console=tty0 console=ttyS0"
	echo "initrd /boot/""$linuxInitRamFS"

	cat << 'CZXWXcRMTo8EmM8i4d'
}
CZXWXcRMTo8EmM8i4d

}

#http://nairobi-embedded.org/making_a_qemu_disk_image_bootable_with_grub.html
_mkboot_sequence() {
	_start
	
	_mustGetSudo
	
	_readLocked "$lock_open_image" && _stop 1
	
	local localFunctionEntryPWD
	localFunctionEntryPWD="$PWD"
	
	cd "$scriptAbsoluteFolder"
	
	_messageNormal "#####Enabling boot."
	
	
	_messageProcess "Opening"
	if ! _openChRoot > /dev/null 2>&1
	then
		_messageFAIL
		_stop 1
	fi
	_messagePASS
	
	_messageProcess "Testing mkdev"
	if ! sudo -n bash -c "type MAKEDEV" > /dev/null 2>&1
	then
		_messageFAIL
		_stop 1
	fi
	if ! _chroot bash -c "type MAKEDEV" > /dev/null 2>&1
	then
		_messageFAIL
		_stop 1
	fi
	_messagePASS
	
	_messageProcess "Testing grub-install"
	if ! sudo -n bash -c "type grub-install" > /dev/null 2>&1
	then
		_messageFAIL
		_stop 1
	fi
	if ! _chroot bash -c "type grub-install" > /dev/null 2>&1
	then
		_messageFAIL
		_stop 1
	fi
	_messagePASS
	
	_messageProcess "Testing grub-mkconfig"
	if ! _chroot bash -c "type grub-mkconfig" > /dev/null 2>&1
	then
		_messageFAIL
		_stop 1
	fi
	_messagePASS
	
	_messageProcess "Installing GRUB"
	
	local imagedev
	imagedev=$(cat "$scriptLocal"/imagedev)
	
	#if ! sudo -n grub-install --root-directory="$chrootDir" --boot-directory="$chrootDir"/boot --modules=part_msdos "$imagedev" >> "$logTmp"/grub.log 2>&1
	if ! _chroot grub-install --boot-directory=/boot --root-directory=/ --modules=part_msdos "$imagedev" >> "$logTmp"/grub.log 2>&1
	then
		_messageFAIL
		_stop 1
	fi
	
	_messagePASS
	
	
	_messageProcess "Configuring GRUB"
	
	_here_mkboot_grubcfg | sudo -n tee "$chrootDir"/boot/grub/grub.cfg > /dev/null 2>&1
	
	#if ! _chroot grub-mkconfig -o /boot/grub/grub.cfg >> "$logTmp"/grub.log 2>&1
	#then
	#	_messageFAIL
	#	_stop 1
	#fi
	
	_messagePASS
	
	_messageProcess "Constructing dev"
	_stopChRoot "$chrootDir" > /dev/null 2>&1
	_wait_umount "$chrootDir"/dev/shm
	_wait_umount "$chrootDir"/dev/pts
	_wait_umount "$chrootDir"/dev
	
	_chroot bash -c "cd /dev ; MAKEDEV generic"
	
	_messagePASS
	
	
	
	
	#_messageProcess "Installing GRUB"
	#
	#_stopChRoot "$chrootDir" > /dev/null 2>&1
	#_wait_umount "$chrootDir"/dev/shm
	#_wait_umount "$chrootDir"/dev/pts
	#_wait_umount "$chrootDir"/dev
	#
	#local imagedev
	#imagedev=$(cat "$scriptLocal"/imagedev)
	#
	#if ! sudo -n grub-install --root-directory="$chrootDir" --boot-directory="$chrootDir"/boot --modules=part_msdos "$imagedev" >> "$logTmp"/grub.log 2>&1
	#if ! _chroot grub-install --boot-directory=/boot --root-directory=/ --modules=part_msdos "$imagedev" >> "$logTmp"/grub.log 2>&1
	#then
	#	_messageFAIL
	#	_stop 1
	#fi
	#
	#_messagePASS
	
	_messageProcess "Closing"
	if ! _closeChRoot > /dev/null 2>&1
	then
		_messageFAIL
		_stop 1
	fi
	_messagePASS
	
	#rm "$logTmp"/grub.log
	cd "$localFunctionEntryPWD"
	_stop
}

_mkboot() {
	"$scriptAbsoluteLocation" _mkboot_sequence "$@"
}


_test_mkboot() {
	_mustGetSudo
	
	_getDep grub-install
	_getDep MAKEDEV
}

_testDistro() {
	_getDep sha256sum
	_getDep sha512sum
	_getDep axel
}

#"$1" == storageLocation (optional)
_test_fetchDebian() {
	if ! ls /usr/share/keyrings/debian-role-keys.gpg > /dev/null 2>&1
	then
		echo 'Debian Keyring missing.'
		echo 'apt-get install debian-keyring'
		_mustGetSudo
		sudo -n apt-get install -y debian-keyring
		! ls /usr/share/keyrings/debian-role-keys.gpg && _stop 1
	fi
}

_fetch_x64_debianLiteISO_sequence() {
	_start
	
	export functionEntryPWD="$PWD"
	
	export storageLocation="$scriptAbsoluteFolder"/_lib/os/
	[[ "$1" != "" ]] && export storageLocation=$(_getAbsoluteLocation "$1")
	
	_test_fetchDebian
	
	cd "$safeTmp"
	
	local debAvailableVersion
	#debAvailableVersion="current"	#Does not work, incorrect image name.
	#debAvailableVersion="9.1.0"
	#debAvailableVersion="9.2.1"
	debAvailableVersion="9.3.0"
	
	[[ -e "$storageLocation"/debian-"$debAvailableVersion"-amd64-netinst.iso ]] && cp "$storageLocation"/debian-"$debAvailableVersion"-amd64-netinst.iso ./debian-"$debAvailableVersion"-amd64-netinst.iso > /dev/null 2>&1
	[[ -e ./debian-"$debAvailableVersion"-amd64-netinst.iso ]] || _fetch 'https://cdimage.debian.org/debian-cd/'"$debAvailableVersion"'/amd64/iso-cd/debian-'"$debAvailableVersion"'-amd64-netinst.iso'
	
	wget 'https://cdimage.debian.org/debian-cd/'"$debAvailableVersion"'/amd64/iso-cd/SHA512SUMS'
	
	wget 'https://cdimage.debian.org/debian-cd/'"$debAvailableVersion"'/amd64/iso-cd/SHA512SUMS.sign'
	
	if ! cat SHA512SUMS | grep debian-"$debAvailableVersion"-amd64-netinst.iso | sha512sum -c - > /dev/null 2>&1
	then
		echo 'invalid'
		_stop 1
	fi
	
	if ! gpgv --keyring /usr/share/keyrings/debian-role-keys.gpg ./SHA512SUMS.sign ./SHA512SUMS
	then
		echo 'invalid'
		_stop 1
	fi
	
	mkdir -p "$storageLocation"
	
	cd "$functionEntryPWD"
	mv "$safeTmp"/debian-"$debAvailableVersion"-amd64-netinst.iso "$storageLocation"
	
	_stop
}

_fetch_x64_DebianLiteISO() {
	
	"$scriptAbsoluteLocation" _fetch_x64_debianLiteISO_sequence "$@"
	
}

#Installs to a raw disk image using QEMU. Subsequently may be run under a variety of real and virtual platforms.
_create_x64_debianLiteVM_sequence() {
	_start
	
	_fetch_x64_DebianLiteISO || _stop 1
	
	_createRawImage
	
	_checkDep qemu-system-x86_64
	
	local debAvailableVersion
	#debAvailableVersion="current"	#Does not work, incorrect image name.
	#debAvailableVersion="9.1.0"
	#debAvailableVersion="9.2.1"
	debAvailableVersion="9.3.0"
	
	qemu-system-x86_64 -machine accel=kvm -drive format=raw,file="$scriptLocal"/vm.img -cdrom "$scriptAbsoluteFolder"/_lib/os/debian-"$debAvailableVersion"-amd64-netinst.iso -boot d -m 1536
	
	_stop
}

_create_x64_debianLiteVM() {
	
	"$scriptAbsoluteLocation" _create_x64_debianLiteVM_sequence "$@"
	
}

_create_arm_debianLiteVM() {
	true
}



#####

_fetch_raspbian_sequence() {
	_start
	
	export functionEntryPWD="$PWD"
	
	export storageLocation="$scriptAbsoluteFolder"/_lib/os/
	[[ "$1" != "" ]] && export storageLocation=$(_getAbsoluteLocation "$1")
	
	cd "$safeTmp"
	
	[[ -e "$storageLocation"/2017-09-07-raspbian-stretch.zip ]] && cp "$storageLocation"/2017-09-07-raspbian-stretch.zip ./2017-09-07-raspbian-stretch.zip > /dev/null 2>&1
	[[ -e ./2017-09-07-raspbian-stretch.zip ]] || _fetch 'https://downloads.raspberrypi.org/raspbian/images/raspbian-2017-09-08/2017-09-07-raspbian-stretch.zip'
	
	wget https://downloads.raspberrypi.org/raspbian/images/raspbian-2017-09-08/2017-09-07-raspbian-stretch.zip.sha256
	
	if ! cat 2017-09-07-raspbian-stretch.zip.sha256 | grep 2017-09-07-raspbian-stretch.zip | sha256sum -c - > /dev/null 2>&1
	then
		echo 'invalid'
		_stop 1
	fi
	
	#Raspbian signature is difficult to authenticate. Including hash here allows some trust to be established from a Git/SSH server, as well HTTPS generally.
	if [[ "$(cat 2017-09-07-raspbian-stretch.zip.sha256 | cut -f1 -d\  )" != "a64d742bc525b548f0435581fac5876b50a4e9ba1d1cd6433358b4ab6c7a770b" ]]
	then
		echo 'invalid'
		_stop 1
	fi
	
	mkdir -p "$storageLocation"
	
	cd "$functionEntryPWD"
	mv "$safeTmp"/2017-09-07-raspbian-stretch.zip "$storageLocation"
	
	
	
	_stop
}

_fetch_raspbian() {
	
	"$scriptAbsoluteLocation" _fetch_raspbian_sequence "$@"
	
}

_create_raspbian_sequence() {
	_start
	
	export functionEntryPWD="$PWD"
	
	_fetch_raspbian || _stop 1
	
	export storageLocation="$scriptAbsoluteFolder"/_lib/os/
	
	cd "$storageLocation"
	
	unzip "$scriptAbsoluteFolder"/_lib/os/2017-09-07-raspbian-stretch.zip
	
	export raspbianImageFile="$scriptLocal"/vm-raspbian.img
	
	[[ ! -e "$raspbianImageFile" ]] && mv "$scriptAbsoluteFolder"/_lib/os/2017-09-07-raspbian-stretch.img "$raspbianImageFile"
	
	cd "$functionEntryPWD"
	
	_stop
}

_create_raspbian() {
	
	"$scriptAbsoluteLocation" _create_raspbian_sequence "$@"
	
}

#Installs to a raw disk image using VirtualBox. Subsequently may be run under a variety of real and virtual platforms.
_create_msw_vbox_sequence() {
	_start
	
	[[ ! -e "$scriptLocal"/msw.iso ]] && _stop 1
	
	#[[ "$vmSize" == "" ]] && export vmSize="15256"
	[[ "$vmSize" == "" ]] && export vmSize="30256"
	
	[[ ! -e "$scriptLocal"/vm.img ]] && [[ ! -e "$scriptLocal"/vm.vdi ]] && _createRawImage
	
	_checkDep VBoxManage
	
	_prepare_instance_vbox || return 1
	
	_readLocked "$vBox_vdi" && return 1
	
	_createLocked "$vBox_vdi" || return 1
	
	#VBoxManage modifymedium "$scriptLocal"/vm.vdi --type normal
	
	export vboxDiskMtype="normal"
	_create_instance_vbox "$@"
	
	#####Actually mount MSW ISO.
	VBoxManage storageattach "$sessionid" --storagectl "IDE Controller" --port 1 --device 0 --type dvddrive --medium "$scriptLocal"/msw.iso
	
	env HOME="$VBOX_USER_HOME_short" VirtualBox
	
	_wait_instance_vbox
	
	#VBoxManage modifymedium "$scriptLocal"/vm.vdi --type multiattach
	
	rm -f "$vBox_vdi" > /dev/null 2>&1
	
	_rm_instance_vbox
	
	_stop
}

_create_msw_vbox() {
	"$scriptAbsoluteLocation" _create_msw_vbox_sequence "$@"
}


#Installs to a raw disk image using QEMU. Subsequently may be run under a variety of real and virtual platforms.
_create_msw_qemu_sequence() {
	_start
	
	[[ ! -e "$scriptLocal"/msw.iso ]] && _stop 1
	
	#[[ "$vmSize" == "" ]] && export vmSize="15256"
	[[ "$vmSize" == "" ]] && export vmSize="30256"
	
	[[ ! -e "$scriptLocal"/vm.img ]] && _createRawImage
	
	_checkDep qemu-system-x86_64
	
	qemu-system-x86_64 -smp 4 -machine accel=kvm -drive format=raw,file="$scriptLocal"/vm.img -cdrom "$scriptLocal"/msw.iso -boot d -m 1536 -net nic,model=rtl8139 -net user -usbdevice tablet -vga cirrus -show-cursor
	
	_stop
}

_create_msw_qemu() {
	"$scriptAbsoluteLocation" _create_msw_qemu_sequence "$@"
}

_create_msw() {
	_create_msw_vbox "$@"
}

_testX11() {
	_getDep xclip
	
	_getDep xinput
}

_report_xi() {
	_messagePlain_probe "$xi_devID"
	_messagePlain_probe "$xi_state"
	_messagePlain_probe "$xi_propNumber"
} 

_x11_clipboard_sendText() {
	xclip -selection clipboard
	#xclip -selection primary
	#xclip -selection secondary
}

_x11_clipboard_getImage() {
	xclip -selection clipboard -t image/png -o -
}

_x11_clipboard_getImage_base64() {
	_x11_clipboard_getImage | base64 -w0
}

_x11_clipboard_getImage_HTML() {
	echo -e -n '<img src="data:image/png;base64,'
	_x11_clipboard_getImage_base64
	echo -e -n '" />'
}

_x11_clipboard_imageToHTML() {
	_x11_clipboard_getImage_HTML | _x11_clipboard_sendText
}

[[ "$DISPLAY" != "" ]] && alias _clipImageHTML=_x11_clipboard_imageToHTML

#KDE can lockup for many reasons, including xrandr, xsetwacom operations. Resetting the driving applications can be an effective workaround to improve reliability.
_reset_KDE() {
	if pgrep plasmashell
	then
		kquitapp plasmashell ; sleep 3 ; plasmashell &
	fi
}

_test_vboxconvert() {
	_getDep VBoxManage
}

_vdi_to_img() {
	VBoxManage clonehd "$scriptLocal"/vm.vdi "$scriptLocal"/vm.img --format RAW
}

#No production use. Not recommended except to accommodate MSW hosts.
_img_to_vdi() {
	VBoxManage convertdd "$scriptLocal"/vm.vdi "$scriptLocal"/vm.img --format VDI 
}

#No production use. Take care to ensure neither "vm.vdi" nor "/dev/nbd0" are not in use.
_vdi_gparted() {
	sudo -n modprobe nbd
	sudo -n qemu-nbd -c /dev/nbd0 "$scriptLocal"/vm.vdi
	
	sudo -n partprobe
	
	kdesudo gparted /dev/nbd0
	
	sudo -n qemu-nbd -d /dev/nbd0
}

#No production use.
_vdi_resize() {
	mv "$scriptLocal"/vm.vdi "$scriptLocal"/vm-big.vdi
	
	#Accommodates 8024MiB.
	VBoxManage createhd --filename "$scriptLocal"/vm-small.vdi --size 8512
	
	sudo -n modprobe nbd max_part=15
	sudo -n qemu-nbd -c /dev/nbd0 "$scriptLocal"/vm-big.vdi
	sudo -n qemu-nbd -c /dev/nbd1 "$scriptLocal"/vm-small.vdi
	sudo -n partprobe
	
	#sudo -n dd if=/dev/nbd0 of=/dev/nbd1 bs=446 count=1
	sudo -n dd if=/dev/nbd0 of=/dev/nbd1 bs=1M count=8512
	sudo -n partprobe
	
	
	
	
	
	
	
	kdesudo gparted /dev/nbd0 /dev/nbd1
	
	sudo -n qemu-nbd -d /dev/nbd0
	sudo -n qemu-nbd -d /dev/nbd1
	
	mv "$scriptLocal"/vm-small.vdi "$scriptLocal"/vm.vdi
	
	#qemu-img convert -f vdi -O qcow2 vm.vdi vm.qcow2
	#qemu-img resize vm.qcow2 8512M
	
	#VBoxManage clonehd "$scriptLocal"/vm.vdi "$scriptLocal"/vm-small.vdi --existing
	#VBoxManage modifyhd "$scriptLocal"/vm-small.vdi --resize 8512
}

_test_gparted() {
	_getDep gparted
}

_gparted_sequence() {
	_start
	
	_mustGetSudo
	
	_openLoop || _stop 1
	
	local imagedev
	imagedev=$(cat "$scriptLocal"/imagedev)
	
	sudo -n gparted "$imagedev"
	
	_closeLoop || _stop 1
	
	_stop
}

_gparted() {
	"$scriptAbsoluteLocation" _gparted_sequence
}

_setupUbiquitous_here() {
	cat << CZXWXcRMTo8EmM8i4d
export profileScriptLocation="$ubcoreUBdir"/ubiquitous_bash.sh
export profileScriptFolder="$ubcoreUBdir"
[[ "\$scriptAbsoluteLocation" != "" ]] && . "\$scriptAbsoluteLocation" --parent _importShortcuts
[[ "\$scriptAbsoluteLocation" == "" ]] && . "\$profileScriptLocation" --profile _importShortcuts
true
CZXWXcRMTo8EmM8i4d
}

_configureLocal() {
	_configureFile "$1" "_local"
}

_configureFile() {
	cp "$scriptAbsoluteFolder"/"$1" "$scriptAbsoluteFolder"/"$2"
}

_configureOps() {
	echo "$@" >> "$scriptAbsoluteFolder"/ops
}

_resetOps() {
	rm "$scriptAbsoluteFolder"/ops
}

_importShortcuts() {
	_tryExec "_resetFakeHomeEnv"
	
	if ! [[ "$PATH" == *":""$HOME""/bin"* ]] && ! [[ "$PATH" == "$HOME""/bin"* ]] && [[ -e "$HOME"/bin ]] && [[ -d "$HOME"/bin ]]
	then
		export PATH="$PATH":"$HOME"/bin
	fi
	
	_tryExec "_visualPrompt"
	
	_tryExec "_scopePrompt"
}

_gitPull_ubiquitous() {
	git pull
}

_gitClone_ubiquitous() {
	git clone --depth 1 git@github.com:mirage335/ubiquitous_bash.git
}

_selfCloneUbiquitous() {
	"$scriptBin"/.ubrgbin.sh _ubrgbin_cpA "$scriptBin" "$ubcoreUBdir"/ > /dev/null 2>&1
	cp -a "$scriptAbsoluteFolder"/lean.sh "$ubcoreUBdir"/lean.sh > /dev/null 2>&1
	cp -a "$scriptAbsoluteLocation" "$ubcoreUBdir"/ubiquitous_bash.sh
}

_installUbiquitous() {
	local localFunctionEntryPWD
	localFunctionEntryPWD="$PWD"
	
	cd "$ubcoreDir"
	
	cd "$ubcoreUBdir"
	_messagePlain_nominal 'attempt: git pull'
	if [[ "$nonet" != "true" ]] && type git > /dev/null 2>&1
	then
		
		local ub_gitPullStatus
		git pull
		ub_gitPullStatus="$?"
		! cd "$localFunctionEntryPWD" && return 1
		
		[[ "$ub_gitPullStatus" == "0" ]] && _messagePlain_good 'pass: git pull' cd "$localFunctionEntryPWD" && return 0
	fi
	_messagePlain_warn 'fail: git pull'
	
	cd "$ubcoreDir"
	_messagePlain_nominal 'attempt: git clone'
	[[ "$nonet" != "true" ]] && type git > /dev/null 2>&1 && [[ ! -e ".git" ]] && _gitClone_ubiquitous && _messagePlain_good 'pass: git clone' && return 0
	_messagePlain_warn 'fail: git clone'
	
	cd "$ubcoreDir"
	_messagePlain_nominal 'attempt: self clone'
	[[ -e ".git" ]] && _messagePlain_bad 'fail: self clone' && return 1
	_selfCloneUbiquitous && return 0
	_messagePlain_bad 'fail: self clone' && return 1
	
	return 0
	
	cd "$localFunctionEntryPWD"
}


_setupUbiquitous() {
	_messageNormal "init: setupUbiquitous"
	local ubHome
	ubHome="$HOME"
	[[ "$1" != "" ]] && ubHome="$1"
	
	export ubcoreDir="$ubHome"/.ubcore
	export ubcoreFile="$ubcoreDir"/.ubcorerc
	
	export ubcoreUBdir="$ubcoreDir"/ubiquitous_bash
	export ubcoreUBfile="$ubcoreDir"/ubiquitous_bash/ubiquitous_bash.sh
	
	_messagePlain_probe 'ubHome= '"$ubHome"
	_messagePlain_probe 'ubcoreDir= '"$ubcoreDir"
	_messagePlain_probe 'ubcoreFile= '"$ubcoreFile"
	
	_messagePlain_probe 'ubcoreUBdir= '"$ubcoreUBdir"
	_messagePlain_probe 'ubcoreUBfile= '"$ubcoreUBfile"
	
	mkdir -p "$ubcoreUBdir"
	! [[ -e "$ubcoreUBdir" ]] && _messagePlain_bad 'missing: ubcoreUBdir= '"$ubcoreUBdir" && _messageFAIL && return 1
	
	
	_messageNormal "install: setupUbiquitous"
	! _installUbiquitous && _messageFAIL && return 1
	! [[ -e "$ubcoreUBfile" ]] && _messagePlain_bad 'missing: ubcoreUBfile= '"$ubcoreUBfile" && _messageFAIL && return 1
	
	
	_messageNormal "hook: setupUbiquitous"
	! _permissions_ubiquitous_repo "$ubcoreUBdir" && _messagePlain_bad 'permissions: ubcoreUBdir = '"$ubcoreUBdir" && _messageFAIL && return 1
	
	mkdir -p "$ubHome"/bin/
	ln -sf "$ubcoreUBfile" "$ubHome"/bin/ubiquitous_bash.sh
	
	_setupUbiquitous_here > "$ubcoreFile"
	! [[ -e "$ubcoreFile" ]] && _messagePlain_bad 'missing: ubcoreFile= '"$ubcoreFile" && _messageFAIL && return 1
	
	
	! grep ubcore "$ubHome"/.bashrc > /dev/null 2>&1 && _messagePlain_probe "$ubcoreFile"' >> '"$ubHome"/.bashrc && echo ". ""$ubcoreFile" >> "$ubHome"/.bashrc
	! grep ubcore "$ubHome"/.bashrc > /dev/null 2>&1 && _messagePlain_bad 'missing: bashrc hook' && _messageFAIL && return 1
	
	
	echo "Now import new functionality into current shell if not in current shell."
	echo ". "'"'"$scriptAbsoluteLocation"'"' --profile _importShortcuts
	
	
	return 0
}

_setupUbiquitous_nonet() {
	local oldNoNet
	oldNoNet="$nonet"
	export nonet="true"
	_setupUbiquitous "$@"
	[[ "$oldNoNet" != "true" ]] && export nonet="$oldNoNet"
}

_upgradeUbiquitous() {
	_setupUbiquitous
}

_resetUbiquitous_sequence() {
	_start
	
	[[ ! -e "$HOME"/.bashrc ]] && return 0
	cp "$HOME"/.bashrc "$HOME"/.bashrc.bak
	cp "$HOME"/.bashrc "$safeTmp"/.bashrc
	grep -v 'ubcore' "$safeTmp"/.bashrc > "$safeTmp"/.bashrc.tmp
	mv "$safeTmp"/.bashrc.tmp "$HOME"/.bashrc
	
	[[ ! -e "$HOME"/.ubcore ]] && return 0
	rm "$HOME"/.ubcorerc
	
	_stop
}

_resetUbiquitous() {
	"$scriptAbsoluteLocation" _resetUbiquitous_sequence
}

_refresh_anchors_ubiquitous() {
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_ubide
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_ubdb
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_true
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_false
}

_anchor() {
	[[ "$scriptAbsoluteFolder" == *"ubiquitous_bash" ]] && _refresh_anchors_ubiquitous
	
	if type "_refresh_anchors" > /dev/null 2>&1
	then
		_tryExec "_refresh_anchors"
		return
	fi
	
	return 0
}


#####Basic Variable Management

#####Global variables.
#Fixed unique identifier for ubiquitious bash created global resources, such as bootdisc images to be automaticaly mounted by guests. Should NEVER be changed.
export ubiquitiousBashIDnano=uk4u
export ubiquitiousBashIDshort="$ubiquitiousBashIDnano"PhB6
export ubiquitiousBashID="$ubiquitiousBashIDshort"63kVcygT0q

##Parameters
#"--shell", ""
#"--profile"
#"--parent", "--return", "--devenv"
#"--call", "--script" "--bypass"
if [[ "$ub_import_param" == "--profile" ]]
then
	ub_import=true
	export scriptAbsoluteLocation="$profileScriptLocation"
	export scriptAbsoluteFolder="$profileScriptFolder"
	export sessionid=$(_uid)
	_messagePlain_probe_expr 'profile: scriptAbsoluteLocation= '"$scriptAbsoluteLocation"'\n ''profile: scriptAbsoluteFolder= '"$scriptAbsoluteFolder"'\n ''profile: sessionid= '"$sessionid" | _user_log-ub
elif ([[ "$ub_import_param" == "--parent" ]] || [[ "$ub_import_param" == "--embed" ]] || [[ "$ub_import_param" == "--return" ]] || [[ "$ub_import_param" == "--devenv" ]])  && [[ "$scriptAbsoluteLocation" != "" ]] && [[ "$scriptAbsoluteFolder" != "" ]] && [[ "$sessionid" != "" ]]
then
	ub_import=true
	true #Do not override.
	_messagePlain_probe_expr 'parent: scriptAbsoluteLocation= '"$scriptAbsoluteLocation"'\n ''parent: scriptAbsoluteFolder= '"$scriptAbsoluteFolder"'\n ''parent: sessionid= '"$sessionid" | _user_log-ub
elif [[ "$ub_import_param" == "--call" ]] || [[ "$ub_import_param" == "--script" ]] || [[ "$ub_import_param" == "--bypass" ]] || [[ "$ub_import_param" == "--shell" ]] || ([[ "$ub_import" == "true" ]] && [[ "$ub_import_param" == "" ]])
then
	ub_import=true
	export scriptAbsoluteLocation="$importScriptLocation"
	export scriptAbsoluteFolder="$importScriptFolder"
	export sessionid=$(_uid)
	_messagePlain_probe_expr 'call: scriptAbsoluteLocation= '"$scriptAbsoluteLocation"'\n ''call: scriptAbsoluteFolder= '"$scriptAbsoluteFolder"'\n ''call: sessionid= '"$sessionid" | _user_log-ub
elif [[ "$ub_import" != "true" ]]	#"--shell", ""
then
	export scriptAbsoluteLocation=$(_getScriptAbsoluteLocation)
	export scriptAbsoluteFolder=$(_getScriptAbsoluteFolder)
	export sessionid=$(_uid)
	_messagePlain_probe_expr 'default: scriptAbsoluteLocation= '"$scriptAbsoluteLocation"'\n ''default: scriptAbsoluteFolder= '"$scriptAbsoluteFolder"'\n ''default: sessionid= '"$sessionid" | _user_log-ub
else	#FAIL, implies [[ "$ub_import" == "true" ]]
	_messagePlain_bad 'import: fall: fail' | _user_log-ub
	return 1 >/dev/null 2>&1
	exit 1
fi
[[ "$importScriptLocation" != "" ]] && export importScriptLocation=
[[ "$importScriptFolder" != "" ]] && export importScriptFolder=

[[ ! -e "$scriptAbsoluteLocation" ]] && _messagePlain_bad 'missing: scriptAbsoluteLocation= '"$scriptAbsoluteLocation" | _user_log-ub && exit 1
[[ "$sessionid" == "" ]] && _messagePlain_bad 'missing: sessionid' | _user_log-ub && exit 1

export lowsessionid=$(echo -n "$sessionid" | tr A-Z a-z )

#Current directory for preservation.
export outerPWD=$(_getAbsoluteLocation "$PWD")

export initPWD="$PWD"
intInitPWD="$PWD"

#Temporary directories.
export safeTmp="$scriptAbsoluteFolder"/w_"$sessionid"
export scopeTmp="$scriptAbsoluteFolder"/s_"$sessionid"
export logTmp="$safeTmp"/log
#Solely for misbehaved applications called upon.
export shortTmp=/tmp/w_"$sessionid"

export scriptBin="$scriptAbsoluteFolder"/_bin
export scriptBundle="$scriptAbsoluteFolder"/_bundle
export scriptLib="$scriptAbsoluteFolder"/_lib
#For trivial installations and virtualized guests. Exclusively intended to support _setupUbiquitous and _drop* hooks.
[[ ! -e "$scriptBin" ]] && export scriptBin="$scriptAbsoluteFolder"
[[ ! -e "$scriptBundle" ]] && export scriptBundle="$scriptAbsoluteFolder"
[[ ! -e "$scriptLib" ]] && export scriptLib="$scriptAbsoluteFolder"


export scriptLocal="$scriptAbsoluteFolder"/_local

#For system installations (exclusively intended to support _setupUbiquitous and _drop* hooks).
if [[ "$scriptAbsoluteLocation" == "/usr/local/bin"* ]] || [[ "$scriptAbsoluteLocation" == "/usr/bin"* ]]
then
	[[ "$scriptAbsoluteLocation" == "/usr/bin"* ]] && export scriptBin="/usr/share/ubcore/bin"
	[[ "$scriptAbsoluteLocation" == "/usr/local/bin"* ]] && export scriptBin="/usr/local/share/ubcore/bin"
	
	if [[ -d "$HOME" ]]
	then
		export scriptLocal="$HOME"/".ubcore"/_sys
	fi
fi

#Essentially temporary tokens which may need to be reused. 
export scriptTokens="$scriptLocal"/.tokens

#Reboot Detection Token Storage
# WARNING WIP. Not tested on all platforms. Requires a directory to be tmp/ram fs mounted. Worst case result is to preserve tokens across reboots.
#Fail-Safe
export bootTmp="$scriptLocal"
#Typical BSD
[[ -d /tmp ]] && export bootTmp='/tmp'
#Typical Linux
[[ -d /dev/shm ]] && export bootTmp='/dev/shm'

#Specialized temporary directories.

# WARNING: Only one user per (virtual) machine. Requires _prepare_abstract . Not default.
# DANGER: Mandatory strict directory 8.3 compliance for this variable! Long subdirectory/filenames permitted thereafter.
# DANGER: Permitting multi-user access to this directory may cause unexpected behavior, including inconsitent file ownership.
#Consistent absolute path abstraction.
export abstractfs_root=/tmp/"$ubiquitiousBashIDnano"
( [[ "$bootTmp" == '/dev/shm' ]] || [[ "$bootTmp" == '/tmp' ]] ) && export abstractfs_root="$bootTmp"/"$ubiquitiousBashIDnano"
export abstractfs_lock=/"$bootTmp"/"$ubiquitiousBashID"/afslock

# Unusually, safeTmpSSH must not be interpreted by client, and therefore is single quoted.
# TODO Test safeTmpSSH variants including spaces in path.
export safeTmpSSH='~/.sshtmp/.s_'"$sessionid"

#Process control.
export pidFile="$safeTmp"/.pid
#Invalid do-not-match default.
export uPID="cwrxuk6wqzbzV6p8kPS8J4APYGX"

export daemonPidFile="$scriptLocal"/.bgpid

#export varStore="$scriptAbsoluteFolder"/var

export vncPasswdFile="$safeTmp"/.vncpasswd

#Network Defaults
export AUTOSSH_FIRST_POLL=45
export AUTOSSH_POLL=45
#export AUTOSSH_GATETIME=0
export AUTOSSH_GATETIME=15

#export AUTOSSH_PORT=0

#export AUTOSSH_DEBUG=1
#export AUTOSSH_LOGLEVEL=7

#Monolithic shared files.
export lock_pathlock="$scriptLocal"/l_path
#Used to make locking operations atomic as possible.
export lock_quicktmp="$scriptLocal"/l_qt
export lock_emergency="$scriptLocal"/l_em
export lock_open="$scriptLocal"/l_o
export lock_opening="$scriptLocal"/l_opening
export lock_closed="$scriptLocal"/l_closed
export lock_closing="$scriptLocal"/l_closing
export lock_instance="$scriptLocal"/l_instance
export lock_instancing="$scriptLocal"/l_instancing

#Specialized lock files. Recommend five character or less suffix. Not all of these may yet be implemented.
export specialLocks
specialLocks=""

export lock_open_image="$lock_open"-img
specialLocks+=("$lock_open_image")

export lock_loop_image="$lock_open"-loop
specialLocks+=("$lock_loop_image")

export lock_open_chroot="$lock_open"-chrt
specialLocks+=("$lock_open_chroot")
export lock_open_docker="$lock_open"-dock
specialLocks+=("$lock_open_docker")
export lock_open_vbox="$lock_open"-vbox
specialLocks+=("$lock_open_vbox")
export lock_open_qemu="$lock_open"-qemu
specialLocks+=("$lock_open_qemu")

export specialLock=""
export specialLocks

export ubVirtImageLocal="true"

#Monolithic shared log files.
export importLog="$scriptLocal"/import.log

#Resource directories.
#export guidanceDir="$scriptAbsoluteFolder"/guidance

#Object Dir
export objectDir="$scriptAbsoluteFolder"

#Object Name
export objectName=$(basename "$objectDir")

#Modify PATH to include own directories.
if ! [[ "$PATH" == *":""$scriptAbsoluteFolder"* ]] && ! [[ "$PATH" == "$scriptAbsoluteFolder"* ]]
then
	export PATH="$PATH":"$scriptAbsoluteFolder":"$scriptBin":"$scriptBundle"
fi

export permaLog="$scriptLocal"

export HOST_USER_ID=$(id -u)
export HOST_GROUP_ID=$(id -g)

export globalArcDir="$scriptLocal"/a
export globalArcFS="$globalArcDir"/fs
export globalArcTmp="$globalArcDir"/tmp

export globalBuildDir="$scriptLocal"/b
export globalBuildFS="$globalBuildDir"/fs
export globalBuildTmp="$globalBuildDir"/tmp


#Machine information.
export hostMemoryTotal=$(cat /proc/meminfo | grep MemTotal | tr -cd '[[:digit:]]')
export hostMemoryAvailable=$(cat /proc/meminfo | grep MemAvailable | tr -cd '[[:digit:]]')
export hostMemoryQuantity="$hostMemoryTotal"

export virtGuestUserDrop="ubvrtusr"
export virtGuestUser="$virtGuestUserDrop"
[[ "$HOST_USER_ID" == 0 ]] && export virtGuestUser="root"

export globalVirtDir="$scriptLocal"/v
export globalVirtFS="$globalVirtDir"/fs
export globalVirtTmp="$globalVirtDir"/tmp

export instancedVirtDir="$scriptAbsoluteFolder"/v_"$sessionid"
export instancedVirtFS="$instancedVirtDir"/fs
export instancedVirtTmp="$instancedVirtDir"/tmp

export virtGuestHomeDrop=/home/"$virtGuestUserDrop"
export virtGuestHome="$virtGuestHomeDrop"
[[ "$HOST_USER_ID" == 0 ]] && export virtGuestHome=/root
###export virtGuestHomeRef="$virtGuestHome".ref

export instancedVirtHome="$instancedVirtFS""$virtGuestHome"
###export instancedVirtHomeRef="$instancedVirtHome".ref

export sharedHostProjectDirDefault=""
export sharedGuestProjectDirDefault="$virtGuestHome"/project

export sharedHostProjectDir="$sharedHostProjectDirDefault"
export sharedGuestProjectDir="$sharedGuestProjectDirDefault"

export instancedProjectDir="$instancedVirtHome"/project
export instancedDownloadsDir="$instancedVirtHome"/Downloads

export chrootDir="$globalVirtFS"
export vboxRaw="$scriptLocal"/vmvdiraw.vmdk

#Only globalFakeHome is persistent. All other default home directories are removed in some way by "_stop".
export globalFakeHome="$scriptLocal"/h
export instancedFakeHome="$scriptAbsoluteFolder"/h_"$sessionid"
export shortFakeHome="$shortTmp"/h

#Do not use directly as home directory. Append subdirectories.
export arbitraryFakeHome="$shortTmp"/a

#Default, override.
# WARNING: Do not disable.
export actualFakeHome="$instancedFakeHome"
export fakeHomeEditLib="false"
export keepFakeHome="true"

#Automatically assigns appropriate memory quantities to nested virtual machines.
_vars_vmMemoryAllocationDefault() {
	export vmMemoryAllocationDefault=96
	
	[[ "$hostMemoryQuantity" -lt "500000" ]] && export vmMemoryAllocationDefault=256 && return 1
	
	[[ "$hostMemoryQuantity" -lt "1256000" ]] && export vmMemoryAllocationDefault=512 && return 0
	[[ "$hostMemoryQuantity" -lt "1768000" ]] && export vmMemoryAllocationDefault=1024 && return 0
	[[ "$hostMemoryQuantity" -lt "8000000" ]] && export vmMemoryAllocationDefault=1512 && return 0
	
	[[ "$hostMemoryQuantity" -ge "14000000" ]] && export vmMemoryAllocationDefault=1512 && return 0
	
	return 1
}

#Machine allocation defaults.
_vars_vmMemoryAllocationDefault

export hostToGuestDir="$instancedVirtDir"/htg
export hostToGuestFiles="$hostToGuestDir"/files
export hostToGuestISO="$instancedVirtDir"/htg/htg.iso 

export blockly_orig="$scriptLib"/blockly
export SigBlockly_mod="$scriptLib"/SigBlockly

# TODO Delete entirely if unnecessary.
#export modLanguageName=python
#export modLanguageNameProper=Python

export generatorSource=generators/"$modLanguageName"
export generatorSourceEntry=generators/"$modLanguageName".js


export scriptModules="$scriptLib"/modules

export overlay="$scriptModules"/overlay

export splice="$scriptModules"/splice
export spliceGitdiff="$scriptModules"/splice/gitdiff

export spliceTmp="$safeTmp"/splice
export spliceTmpGitdiff="$spliceTmp"/gitdiff

_prepare_splice() {
	mkdir -p "$spliceTmp"
	mkdir -p "$spliceTmpGitdiff"
}



_prepareFakeHome() {
	mkdir -p "$actualFakeHome"
}

_rm_instance_fakeHome() {
	! [[ -e "$instancedFakeHome" ]] && return 0
	
	[[ -e "$instancedFakeHome" ]] && rmdir "$instancedFakeHome" > /dev/null 2>&1
	
	[[ -e "$instancedFakeHome" ]] && _unmakeFakeHome "$instancedFakeHome" > /dev/null 2>&1
	
	# DANGER Allows folders containing ".git" to be removed in all further shells inheriting this environment!
	export safeToDeleteGit="true"
	[[ -e "$instancedFakeHome" ]] && _safeRMR "$instancedFakeHome"
	export safeToDeleteGit="false"
}

##### VBoxVars
#Only include variables and functions here that might need to be used globally.
_unset_vbox() {
	export vBox_vdi=""
	
	export vBoxInstanceDir=""
	
	export VBOX_ID_FILE=""
	
	export VBOX_USER_HOME=""
	export VBOX_USER_HOME_local=""
	export VBOX_USER_HOME_short=""
	
	export VBOX_IPC_SOCKETID=""
	export VBoxXPCOMIPCD_PIDfile=""
	
	_messagePlain_nominal 'clear: _unset_vbox'
}

_reset_vboxLabID() {
	[[ "$VBOX_ID_FILE" == "" ]] && _messagePlain_bad 'blank: VBOX_ID_FILE' && return 1
	
	rm -f "$VBOX_ID_FILE" > /dev/null 2>&1
	
	[[ -e "$VBOX_ID_FILE" ]] && _messagePlain_bad 'fail: VBOX_ID_FILE exists' && return 1
	
	return 0
}

#"$1" == virtualbox instance directory (optional)
_prepare_vbox() {
	_messagePlain_nominal 'init: _prepare_vbox'
	
	_unset_vbox
	
	export vBox_vdi="$scriptLocal/_vboxvdi"
	
	export vBoxInstanceDir="$scriptLocal"
	[[ "$1" != "" ]] && export vBoxInstanceDir="$1"
	_messagePlain_probe 'vBoxInstanceDir= '"$vBoxInstanceDir"
	
	mkdir -p "$vBoxInstanceDir" > /dev/null 2>&1 || return 1
	mkdir -p "$scriptLocal" > /dev/null 2>&1 || return 1
	mkdir -p "$globalVirtDir" > /dev/null 2>&1 || return 1
	mkdir -p "$globalVirtFS" > /dev/null 2>&1 || return 1
	mkdir -p "$globalVirtTmp" > /dev/null 2>&1 || return 1
	
	export VBOX_ID_FILE
	VBOX_ID_FILE="$vBoxInstanceDir"/vbox.id
	
	! _pathLocked _reset_vboxLabID && _messagePlain_bad 'fail: path has changed and lock not reset' && return 1
	
	[[ ! -e "$VBOX_ID_FILE" ]] && sleep 0.1 && [[ ! -e "$VBOX_ID_FILE" ]] && echo -e -n "$sessionid" > "$VBOX_ID_FILE" 2> /dev/null
	[[ -e "$VBOX_ID_FILE" ]] && export VBOXID=$(cat "$VBOX_ID_FILE" 2> /dev/null)
	
	
	export VBOX_USER_HOME="$vBoxInstanceDir"/vBoxCfg
	export VBOX_USER_HOME_local="$vBoxInstanceDir"/vBoxHome
	#export VBOX_USER_HOME_short="$HOME"/.vbl"$VBOXID"
	#export VBOX_USER_HOME_short=/tmp/.vbl"$VBOXID"
	export VBOX_USER_HOME_short="$bootTmp"/.vbl"$VBOXID"
	
	export VBOX_IPC_SOCKETID="$VBOXID"
	export VBoxXPCOMIPCD_PIDfile="/tmp/.vbox-""$VBOX_IPC_SOCKETID""-ipc/lock"
	
	
	
	[[ "$VBOXID" == "" ]] && _messagePlain_bad 'blank: VBOXID' && return 1
	[[ ! -e "$VBOX_ID_FILE" ]] && _messagePlain_bad 'missing: VBOX_ID_FILE= '"$VBOX_ID_FILE" && return 1
	
	
	mkdir -p "$VBOX_USER_HOME" > /dev/null 2>&1 || return 1
	mkdir -p "$VBOX_USER_HOME_local" > /dev/null 2>&1 || return 1
	
	
	#Atomically ensure symlink between full and short home directory paths is up to date.
	local oldLinkPath
	oldLinkPath=$(readlink "$VBOX_USER_HOME_short")
	[[ "$oldLinkPath" != "$VBOX_USER_HOME_local" ]] && ln -sf "$VBOX_USER_HOME_local" "$VBOX_USER_HOME_short" > /dev/null 2>&1
	oldLinkPath=$(readlink "$VBOX_USER_HOME_short")
	[[ "$oldLinkPath" != "$VBOX_USER_HOME_local" ]] && _messagePlain_bad 'fail: symlink VBOX_USER_HOME_local to VBOX_USER_HOME_short' && return 1
	
	return 0
}

_prepare_lab_vbox() {
	_prepare_vbox "$scriptLocal"
}
#_prepare_lab_vbox


_buildHello() {
	local helloSourceCode
	helloSourceCode="$scriptAbsoluteFolder"/generic/hello/hello.c
	! [[ -e "$helloSourceCode" ]] && helloSourceCode="$scriptLib"/ubiquitous_bash/generic/hello/hello.c
	
	mkdir -p "$scriptBin"
	gcc -o "$scriptBin"/hello -static -nostartfiles "$helloSourceCode"
}

#####Idle

_idle() {
	_start
	
	_checkDep getIdle
	
	_daemonStatus && _stop 1
	
	#Default 20 minutes.
	[[ "$idleMax" == "" ]] && export idleMax=1200000
	[[ "$idleMin" == "" ]] && export idleMin=60000
	
	while true
	do
		sleep 5
		
		idleTime=$("$scriptBin"/getIdle)
		
		if [[ "$idleTime" -lt "$idleMin" ]] && _daemonStatus
		then
			true
			_killDaemon	#Comment out if unnecessary.
		fi
		
		
		if [[ "$idleTime" -gt "$idleMax" ]] && ! _daemonStatus
		then
			_execDaemon
			while ! _daemonStatus
			do
				sleep 5
			done
		fi
		
		
		
	done
	
	_stop
}

_test_buildIdle() {
	_getDep "X11/extensions/scrnsaver.h"
}

_testBuiltIdle() {
	
	_checkDep getIdle
	
	idleTime=$("$scriptBin"/getIdle)
	
	if ! echo "$idleTime" | grep '^[0-9]*$' >/dev/null 2>&1
	then
		echo getIdle invalid response
		_stop 1
	fi
	
}

_buildIdle() {
	local idleSourceCode
	idleSourceCode="$scriptAbsoluteFolder"/generic/process/idle.c
	! [[ -e "$idleSourceCode" ]] && idleSourceCode="$scriptLib"/ubiquitous_bash/generic/process/idle.c
	
	mkdir -p "$scriptBin"
	gcc -o "$scriptBin"/getIdle "$idleSourceCode" -lXss -lX11
	
}

_test_build_prog() {
	true
}

_test_build() {
	_getDep gcc
	_getDep g++
	_getDep make
	
	_getDep cmake
	
	_getDep autoreconf
	_getDep autoconf
	_getDep automake
	
	_getDep libtool
	
	_getDep makeinfo
	
	_getDep pkg-config
	
	_tryExec _test_buildGoSu
	
	_tryExec _test_buildIdle
	
	_tryExec _test_bashdb
	
	_tryExec _test_ethereum_build
	_tryExec _test_ethereum_parity_build
	
	_tryExec _test_build_prog
}
alias _testBuild=_test_build

_buildSequence() {
	_start
	
	echo -e '\E[1;32;46m Binary compiling...	\E[0m'
	
	_tryExec _buildHello
	
	_tryExec _buildIdle
	_tryExec _buildGosu
	
	_tryExec _build_geth
	_tryExec _build_ethereum_parity
	
	_tryExec _buildChRoot
	_tryExec _buildQEMU
	
	_tryExec _buildExtra
	
	echo "     ...DONE"
	
	_stop
}

_build_prog() {
	true
}

_build() {
	"$scriptAbsoluteLocation" _buildSequence
	
	_build_prog
}

#####Local Environment Management (Resources)

_prepare_prog() {
	true
}

_extra() {
	true
}

_prepare_abstract() {
	! mkdir -p "$abstractfs_root" && exit 1
	chmod 0700 "$abstractfs_root" > /dev/null 2>&1
	! chmod 700 "$abstractfs_root" && exit 1
	! chown "$USER":"$USER" "$abstractfs_root" && exit 1
	
	! mkdir -p "$abstractfs_lock" && exit 1
	chmod 0700 "$abstractfs_lock" > /dev/null 2>&1
	! chmod 700 "$abstractfs_lock" && exit 1
	! chown "$USER":"$USER" "$abstractfs_lock" && exit 1
}

_prepare() {
	
	! mkdir -p "$safeTmp" && exit 1
	
	! mkdir -p "$shortTmp" && exit 1
	
	! mkdir -p "$logTmp" && exit 1
	
	! mkdir -p "$scriptLocal" && exit 1
	
	! mkdir -p "$bootTmp" && exit 1
	
	#_prepare_abstract
	
	_extra
	_prepare_prog
}

#####Local Environment Management (Instancing)

_start_prog() {
	true
}

_start() {
	
	_prepare
	
	#touch "$varStore"
	#. "$varStore"
	
	echo $$ > "$safeTmp"/.pid
	echo "$sessionid" > "$safeTmp"/.sessionid
	_embed_here > "$safeTmp"/.embed.sh
	chmod 755 "$safeTmp"/.embed.sh
	
	_start_prog
}

_saveVar_prog() {
	true
}

_saveVar() {
	true
	#declare -p varName > "$varStore"
	
	_saveVar_prog
}

_stop_prog() {
	true
}

_stop() {
	_stop_prog
	
	_preserveLog
	
	#Kill process responsible for initiating session. Not expected to be used normally, but an important fallback.
	local ub_stop_pid
	if [[ -e "$safeTmp"/.pid ]]
	then
		ub_stop_pid=$(cat "$safeTmp"/.pid)
		if [[ $$ != "$ub_stop_pid" ]]
		then
			pkill -P "$ub_stop_pid"
			kill "$ub_stop_pid"
		fi
	fi
	
	rm -f "$pidFile" > /dev/null 2>&1	#Redundant, as this usually resides in "$safeTmp".
	rm -f "$ub_scope" > /dev/null 2>&1	#Symlink, or nonexistent.
	[[ -e "$scopeTmp" ]] && _safeRMR "$scopeTmp"			#Only created if needed by scope.
	_safeRMR "$shortTmp"
	_safeRMR "$safeTmp"
	
	_tryExec _rm_instance_fakeHome
	
	#Optionally always try to remove any systemd shutdown hook.
	#_tryExec _unhook_systemd_shutdown
	
	if [[ "$1" != "" ]]
	then
		exit "$1"
	else
		exit 0
	fi
}

#Do not overload this unless you know why you need it instead of _stop_prog.
_stop_emergency_prog() {
	true
}

#Called upon SIGTERM or similar signal.
_stop_emergency() {
	[[ "$noEmergency" == true ]] && _stop "$1"
	
	export EMERGENCYSHUTDOWN=true
	
	#Not yet using _tryExec since this function would typically result from user intervention, or system shutdown, both emergency situations in which an error message would be ignored if not useful. Higher priority is guaranteeing execution if needed and available.
	_closeChRoot_emergency
	
	#Daemon uses a separate instance, and will not be affected by previous actions, possibly even if running in the foreground.
	#jobs -p >> "$daemonPidFile" #Could derrange the correct order of descendent job termination.
	_tryExec _killDaemon
	
	_tryExec _stop_virtLocal
	
	_stop_emergency_prog
	
	_stop "$1"
	
}

_waitFile() {
	
	[[ -e "$1" ]] && sleep 1
	[[ -e "$1" ]] && sleep 9
	[[ -e "$1" ]] && sleep 27
	[[ -e "$1" ]] && sleep 81
	[[ -e "$1" ]] && _return 1
	
	return 0
}

#Wrapper. If lock file is present, waits for unlocking operation to complete successfully, then reports status.
#"$1" == checkFile
#"$@" == wait command and parameters
_waitFileCommands() {
	local waitCheckFile
	waitCheckFile="$1"
	shift
	
	if [[ -e "$waitCheckFile" ]]
	then
		local waitFileCommandStatus
		
		"$@"
		
		waitFileCommandStatus="$?"
		
		if [[ "$waitFileCommandStatus" != "0" ]]
		then
			return "$waitFileCommandStatus"
		fi
		
		[[ -e "$waitCheckFile" ]] && return 1
		
	fi
	
	return 0
}

#$1 == command to execute if scriptLocal path has changed, typically remove another lock file
_pathLocked() {
	[[ ! -e "$lock_pathlock" ]] && echo "k3riC28hQRLnjgkwjI" > "$lock_pathlock"
	[[ ! -e "$lock_pathlock" ]] && return 1
	
	local lockedPath
	lockedPath=$(cat "$lock_pathlock")
	
	if [[ "$lockedPath" != "$scriptLocal" ]]
	then
		rm -f "$lock_pathlock" > /dev/null 2>&1
		[[ -e "$lock_pathlock" ]] && return 1
		
		echo "$scriptLocal" > "$lock_pathlock"
		[[ ! -e "$lock_pathlock" ]] && return 1
		
		if [[ "$1" != "" ]]
		then
			"$@"
			[[ "$?" != "0" ]] && return 1
		fi
		
	fi
	
	return 0
}

_readLocked() {
	mkdir -p "$bootTmp"
	
	local rebootToken
	rebootToken=$(cat "$1" 2> /dev/null)
	
	#Remove miscellaneous files if appropriate.
	if [[ -d "$bootTmp" ]] && ! [[ -e "$bootTmp"/"$rebootToken" ]]
	then
		rm -f "$scriptLocal"/*.log && rm -f "$scriptLocal"/imagedev && rm -f "$scriptLocal"/WARNING
		
		[[ -e "$lock_quicktmp" ]] && sleep 0.1 && [[ -e "$lock_quicktmp" ]] && rm -f "$lock_quicktmp"
	fi
	
	! [[ -e "$1" ]] && return 1
	##Lock file exists.
	
	if [[ -d "$bootTmp" ]]
	then
		if ! [[ -e "$bootTmp"/"$rebootToken" ]]
		then
			##Lock file obsolete.
			
			#Remove old lock.
			rm -f "$1" > /dev/null 2>&1
			return 1
		fi
		
		##Lock file and token exists.
		return 0
	fi
	
	##Lock file exists, token cannot be found.
	return 0
	
	
	
}

#Using _readLocked before any _createLocked operation is strongly recommended to remove any lock from prior UNIX session (ie. before latest reboot).
_createLocked() {
	[[ "$uDEBUG" == true ]] && caller 0 >> "$scriptLocal"/lock.log
	[[ "$uDEBUG" == true ]] && echo -e '\t'"$sessionid"'\t'"$1" >> "$scriptLocal"/lock.log
	
	mkdir -p "$bootTmp"
	
	! [[ -e "$bootTmp"/"$sessionid" ]] && echo > "$bootTmp"/"$sessionid"
	
	# WARNING Recommend setting this to a permanent value when testing critical subsystems, such as with _userChRoot related operations.
	local lockUID="$(_uid)"
	
	echo "$sessionid" > "$lock_quicktmp"_"$lockUID"
	
	mv -n "$lock_quicktmp"_"$lockUID" "$1" > /dev/null 2>&1
	
	if [[ -e "$lock_quicktmp"_"$lockUID" ]]
	then
		[[ "$uDEBUG" == true ]] && echo -e '\t'FAIL >> "$scriptLocal"/lock.log
		rm -f "$lock_quicktmp"_"$lockUID" > /dev/null 2>&1
		return 1
	fi
	
	rm -f "$lock_quicktmp"_"$lockUID" > /dev/null 2>&1
	return 0
}

_resetLocks() {
	
	_readLocked "$lock_open"
	_readLocked "$lock_opening"
	_readLocked "$lock_closed"
	_readLocked "$lock_closing"
	_readLocked "$lock_instance"
	_readLocked "$lock_instancing"
	
}

_checkSpecialLocks() {
	local localSpecialLock
	
	localSpecialLock="$specialLock"
	[[ "$1" != "" ]] && localSpecialLock="$1"
	
	local currentLock
	
	for currentLock in "${specialLocks[@]}"
	do
		[[ "$currentLock" == "$localSpecialLock" ]] && continue
		_readLocked "$currentLock" && return 0
	done
	
	return 1
}

#Wrapper. Operates lock file for mounting shared resources (eg. persistent virtual machine image). Avoid if possible.
#"$1" == waitOpen function && shift
#"$@" == wrapped function and parameters
#"$specialLock" == additional lockfile to write
_open_sequence() {
	if _readLocked "$lock_open"
	then
		_checkSpecialLocks && return 1
		return 0
	fi
	
	_readLocked "$lock_closing" && return 1
	
	if _readLocked "$lock_opening"
	then
		if _waitFileCommands "$lock_opening" "$1"
		then
			_readLocked "$lock_open" || return 1
			return 0
		else
			return 1
		fi
	fi
	
	_createLocked "$lock_opening" || return 1
	
	shift
	
	echo "LOCKED" > "$scriptLocal"/WARNING
	
	"$@"
	
	if [[ "$?" == "0" ]]
	then
		_createLocked "$lock_open" || return 1
		
		if [[ "$specialLock" != "" ]]
		then
			_createLocked "$specialLock" || return 1
		fi
		
		rm -f "$lock_opening"
		return 0
	fi
	
	return 1
}

_open() {
	local returnStatus
	
	_open_sequence "$@"
	returnStatus="$?"
	
	export specialLock
	specialLock=""
	export specialLock
	
	return "$returnStatus"
}

#Wrapper. Operates lock file for shared resources (eg. persistent virtual machine image). Avoid if possible.
#"$1" == <"--force"> && shift
#"$1" == waitClose function && shift
#"$@" == wrapped function and parameters
#"$specialLock" == additional lockfile to remove
_close_sequence() {
	local closeForceEnable
	closeForceEnable=false
	
	if [[ "$1" == "--force" ]]
	then
		closeForceEnable=true
		shift
	fi
	
	if ! _readLocked "$lock_open" && [[ "$closeForceEnable" != "true" ]]
	then
		return 0
	fi
	
	if [[ "$specialLock" != "" ]] && [[ -e "$specialLock" ]] && ! _readLocked "$specialLock" && [[ "$closeForceEnable" != "true" ]]
	then
		return 1
	fi
	
	_checkSpecialLocks && return 1
	
	if _readLocked "$lock_closing" && [[ "$closeForceEnable" != "true" ]]
	then
		if _waitFileCommands "$lock_closing" "$1"
		then
			return 0
		else
			return 1
		fi
	fi
	
	if [[ "$closeForceEnable" != "true" ]]
	then
		_createLocked "$lock_closing" || return 1
	fi
	! _readLocked "$lock_closing" && _createLocked "$lock_closing"
	
	shift
	
	"$@"
	
	if [[ "$?" == "0" ]]
	then
		rm -f "$lock_open" || return 1
		
		if [[ "$specialLock" != "" ]] && [[ -e "$specialLock" ]]
		then
			rm -f "$specialLock" || return 1
		fi
		
		rm -f "$lock_closing"
		rm -f "$scriptLocal"/WARNING
		return 0
	fi
	
	return 1
}

_close() {
	local returnStatus
	
	_close_sequence "$@"
	returnStatus="$?"
	
	export specialLock
	specialLock=""
	export specialLock
	
	return "$returnStatus"
}

#"$1" == variable name to preserve
#shift
#"$1" == variable data to preserve
#shift
#"$@" == function to prepare other variables
_preserveVar() {
	local varNameToPreserve
	varNameToPreserve="$1"
	shift
	
	local varDataToPreserve
	varDataToPreserve="$1"
	shift
	
	"$@"
	
	[[ "$varNameToPreserve" == "" ]] && return
	[[ "$varDataToPreserve" == "" ]] && return
	
	export "$varNameToPreserve"="$varDataToPreserve"
	
	return
}


#####Installation


_vector() {
	_tryExec "_vector_virtUser"
}

#Verifies the timeout and sleep commands work properly, with subsecond specifications.
_timetest() {
	
	iterations=0
	while [[ "$iterations" -lt 10 ]]
	do
		dateA=$(date +%s)
		
		sleep 0.1
		sleep 0.1
		sleep 0.1
		sleep 0.1
		sleep 0.1
		sleep 0.1
		
		_timeout 0.1 sleep 10
		_timeout 0.1 sleep 10
		_timeout 0.1 sleep 10
		_timeout 0.1 sleep 10
		_timeout 0.1 sleep 10
		_timeout 0.1 sleep 10
		
		dateB=$(date +%s)
		
		dateDelta=$(bc <<< "$dateB - $dateA")
		
		if [[ "$dateDelta" -lt "1" ]]
		then
			_messageFAIL
			_stop 1
		fi
		
		if [[ "$dateDelta" -lt "5" ]]
		then
			_messagePASS
			return 0
		fi
		
		let iterations="$iterations + 1"
	done
	_messageFAIL
	_stop 1
}

_test_prog() {
	true
}

_test() {
	_start
	
	_tryExec "_test_permissions_ubiquitous"
	
	echo -n -e '\E[1;32;46m Argument length...	\E[0m'
	
	local testArgLength
	
	! testArgLength=$(getconf ARG_MAX) && _messageFAIL && _stop 1
	[[ "$testArgLength" -lt 131071 ]] && _messageFAIL && _stop 1
	
	_messagePASS
	
	echo -n -e '\E[1;32;46m Timing...		\E[0m'
	_timetest
	
	_messageNormal "Dependency checking..."
	
	## Check dependencies
	
	#"generic/filesystem"/permissions.sh
	_checkDep stat
	
	_getDep wget
	_getDep grep
	_getDep fgrep
	_getDep sed
	_getDep awk
	_getDep cut
	_getDep head
	_getDep tail
	
	
	_getDep realpath
	_getDep readlink
	_getDep dirname
	_getDep basename
	
	_getDep sleep
	_getDep wait
	_getDep kill
	_getDep jobs
	_getDep ps
	_getDep exit
	
	_getDep env
	_getDep bash
	_getDep echo
	_getDep cat
	_getDep type
	_getDep mkdir
	_getDep trap
	_getDep return
	_getDep set
	
	_getDep printf
	
	_getDep dd
	
	_getDep rm
	
	_getDep find
	_getDep ln
	_getDep ls
	
	_getDep id
	
	_getDep test
	
	_getDep true
	_getDep false
	
	_getDep diff
	
	_tryExec "_test_package"
	
	
	_tryExec "_test_daemon"
	
	_tryExec "_testFindPort"
	_tryExec "_test_waitport"
	
	_tryExec "_testProxySSH"
	
	_tryExec "_testAutoSSH"
	
	_tryExec "_testTor"
	
	_tryExec "_testProxyRouter"
	
	#_tryExec "_test_build"
	
	_tryExec "_testGosu"
	
	_tryExec "_testMountChecks"
	_tryExec "_testBindMountManager"
	_tryExec "_testDistro"
	_tryExec "_test_fetchDebian"
	
	_tryExec "_test_image"
	_tryExec "_test_transferimage"
	
	_tryExec "_testCreatePartition"
	_tryExec "_testCreateFS"
	
	_tryExec "_test_mkboot"
	
	_tryExec "_test_abstractfs"
	_tryExec "_test_fakehome"
	_tryExec "_testChRoot"
	_tryExec "_testQEMU"
	_tryExec "_testQEMU_x64-x64"
	_tryExec "_testQEMU_x64-raspi"
	_tryExec "_testQEMU_raspi-raspi"
	_tryExec "_testVBox"
	
	_tryExec "_test_vboxconvert"
	
	_tryExec "_test_dosbox"
	
	_tryExec "_testWINE"
	
	_tryExec "_test_docker"
	
	_tryExec "_test_docker_mkimage"
	
	_tryExec "_testVirtBootdisc"
	
	_tryExec "_testExtra"
	
	_tryExec "_testGit"
	
	_tryExec "_test_bup"
	
	_tryExec "_testX11"
	
	_tryExec "_test_virtLocal_X11"
	
	_tryExec "_test_gparted"
	
	_tryExec "_test_synergy"
	
	_tryExec "_test_devatom"
	_tryExec "_test_devemacs"
	_tryExec "_test_deveclipse"
	
	_tryExec "_test_ethereum"
	_tryExec "_test_ethereum_parity"
	
	[[ -e /dev/urandom ]] || echo /dev/urandom missing _stop
	
	_messagePASS
	
	_messageNormal 'Vector...'
	_vector
	_messagePASS
	
	_test_prog
	
	_stop
}

_testBuilt_prog() {
	true
}

_testBuilt() {
	_start
	
	_messageProcess "Binary checking"
	
	_tryExec "_testBuiltIdle"
	_tryExec "_testBuiltGosu"	#Note, requires sudo, not necessary for docker .
	
	_tryExec "_test_ethereum_built"
	_tryExec "_test_ethereum_parity_built"
	
	_tryExec "_testBuiltChRoot"
	_tryExec "_testBuiltQEMU"
	
	_tryExec "_testBuiltExtra"
	
	_testBuilt_prog
	
	_messagePASS
	
	_stop
}

#Creates symlink in "$HOME"/bin, to the executable at "$1", named according to its residing directory and file name.
_setupCommand() {
	mkdir -p "$HOME"/bin
	! [[ -e "$HOME"/bin ]] && return 1
	
	local clientScriptLocation
	clientScriptLocation=$(_getAbsoluteLocation "$1")
	
	local clientScriptFolder
	clientScriptFolder=$(_getAbsoluteFolder "$1")
	
	local commandName
	commandName=$(basename "$1")
	
	local clientName
	clientName=$(basename "$clientScriptFolder")
	
	_relink_relative "$clientScriptLocation" "$HOME"/bin/"$commandName""-""$clientName"
	
	
}

_setupCommand_meta() {
	mkdir -p "$HOME"/bin
	! [[ -e "$HOME"/bin ]] && return 1
	
	local clientScriptLocation
	clientScriptLocation=$(_getAbsoluteLocation "$1")
	
	local clientScriptFolder
	clientScriptFolder=$(_getAbsoluteFolder "$1")
	
	local clientScriptFolderResidence
	clientScriptFolderResidence=$(_getAbsoluteFolder "$clientScriptFolder")
	
	local commandName
	commandName=$(basename "$1")
	
	local clientName
	clientName=$(basename "$clientScriptFolderResidence")
	
	_relink_relative "$clientScriptLocation" "$HOME"/bin/"$commandName""-""$clientName"
	
	
}

_find_setupCommands() {
	find -L "$scriptAbsoluteFolder" -not \( -path \*_arc\* -prune \) "$@"
}

#Consider placing files like ' _vnc-machine-"$netName" ' in an "_index" folder for automatic installation.
_setupCommands() {
	#_find_setupCommands -name '_command' -exec "$scriptAbsoluteLocation" _setupCommand {} \;
	
	_tryExec "_setup_ssh_commands"
	_tryExec "_setup_command_commands"
}

_setup_pre() {
	true
}

_setup_prog() {
	true
}

_setup() {
	_start
	
	"$scriptAbsoluteLocation" _test || _stop 1
	
	#Only attempt build procedures if their functions have been defined from "build.sh" . Pure shell script projects (eg. CoreAutoSSH), and projects using only statically compiled binaries, need NOT include such procedures.
	local buildSupported
	type _build > /dev/null 2>&1 && type _test_build > /dev/null 2>&1 && buildSupported="true"
	
	[[ "$buildSupported" == "true" ]] && ! "$scriptAbsoluteLocation" _test_build && _stop 1
	
	if ! "$scriptAbsoluteLocation" _testBuilt
	then
		! [[ "$buildSupported" == "true" ]] && _stop 1
		[[ "$buildSupported" == "true" ]] && ! "$scriptAbsoluteLocation" _build "$@" && _stop 1
		! "$scriptAbsoluteLocation" _testBuilt && _stop 1
	fi
	
	_setupCommands
	
	_setup_pre
	
	_tryExec "_setup_ssh"
	
	_setup_prog
	
	_stop
}

_test_package() {
	_getDep tar
	_getDep gzip
}

_package_prog() {
	true
}

# WARNING Must define "_package_license" function in ops to include license files in package!
_package() {
	_start
	mkdir -p "$safeTmp"/package
	
	_package_prog
	
	_tryExec "_package_license"
	
	_tryExec "_package_cautossh"
	
	#scriptBasename=$(basename "$scriptAbsoluteLocation")
	#cp -a "$scriptAbsoluteLocation" "$safeTmp"/package/"$scriptBasename"
	cp -a "$scriptAbsoluteLocation" "$safeTmp"/package/
	cp -a "$scriptAbsoluteFolder"/ops "$safeTmp"/package/
	
	#cp -a "$scriptAbsoluteFolder"/_bin "$safeTmp"
	#cp -a "$scriptAbsoluteFolder"/_config "$safeTmp"
	#cp -a "$scriptAbsoluteFolder"/_prog "$safeTmp"
	
	#cp -a "$scriptAbsoluteFolder"/_local "$safeTmp"/package/
	
	cp -a "$scriptAbsoluteFolder"/README.md "$safeTmp"/package/
	cp -a "$scriptAbsoluteFolder"/USAGE.html "$safeTmp"/package/
	
	cd "$safeTmp"/package/
	tar -czvf "$scriptAbsoluteFolder"/package.tar.gz .
	
	cd "$outerPWD"
	_stop
}

_test_prog() {
	_getDep rsync
}

##### Core

_refresh_overlay() {
	_safeRMR "$scriptModules"/overlay/
	
	mkdir -p "$overlay"/
	cp -a "$SigBlockly_mod"/_code.html "$overlay"/
	cp -a "$SigBlockly_mod"/_blockfactory.html "$overlay"/
	
	mkdir -p "$overlay"/blocks/
	cp -a "$SigBlockly_mod"/blocks/arbitrary.js "$overlay"/blocks/arbitrary.js
	cp -a "$SigBlockly_mod"/blocks/bash.js "$overlay"/blocks/bash.js
	cp -a "$SigBlockly_mod"/blocks/c.js "$overlay"/blocks/c.js
	cp -a "$SigBlockly_mod"/blocks/ub.js "$overlay"/blocks/ub.js
	
	mkdir -p "$overlay"/generators/bash/
	mkdir -p "$overlay"/generators/c/
	cp -a "$SigBlockly_mod"/generators/bash/. "$overlay"/generators/bash/
	cp -a "$SigBlockly_mod"/generators/c/. "$overlay"/generators/c/
	
	mkdir -p "$overlay"/generators/bash/
	mkdir -p "$overlay"/generators/c/
	mkdir -p "$overlay"/generators/dart/
	mkdir -p "$overlay"/generators/javascript/
	mkdir -p "$overlay"/generators/lua/
	mkdir -p "$overlay"/generators/php/
	mkdir -p "$overlay"/generators/python/
	cp -a "$SigBlockly_mod"/generators/dart/arbitrary.js "$overlay"/generators/dart/
	cp -a "$SigBlockly_mod"/generators/javascript/arbitrary.js "$overlay"/generators/javascript/
	cp -a "$SigBlockly_mod"/generators/lua/arbitrary.js "$overlay"/generators/lua/
	cp -a "$SigBlockly_mod"/generators/php/arbitrary.js "$overlay"/generators/php/
	cp -a "$SigBlockly_mod"/generators/python/arbitrary.js "$overlay"/generators/python/
	
	mkdir -p "$overlay"/demos/code/
	cp -a "$SigBlockly_mod"/demos/code/. "$overlay"/demos/code/
}

# TODO: Not implemented.
_apply_overlay() {
	true
}

_update_SigBlockly() {
	local localFunctionEntryPWD
	localFunctionEntryPWD="$PWD"
	
	! cd "$SigBlockly_mod" && return 1
	
	git reset --hard
	
	#git pull upstream master
	
	#https://stackoverflow.com/questions/15232000/git-ignore-files-during-merge
	#https://stackoverflow.com/questions/41101998/git-checkout-vs-git-checkout
	git merge --no-ff --no-commit upstream/master
	git reset HEAD LICENSE
	git reset HEAD README.md
	git checkout -- LICENSE
	git checkout -- README.md
	#git commit -m "merged <merge-branch>"
	
	
	cd "$localFunctionEntryPWD"
}

#"$1" == $modSource
#"$2" == $modDestination
#"$3" == path
_modTransfer() {
	rsync -q -ax --exclude "/.git" "$1"/"$3" "$2"/"$3"
}

#languageName == "$1"
#languageNameProper == "$2"
#spliceCodeGitdiff == "$3"
_splice_generator_filter() {
	local languageName
	languageName="$1"
	local languageNameProper
	languageNameProper="$2"
	local spliceCodeGitdiff
	spliceCodeGitdiff="$3"
	
	sed -i 's/$languageNameProper/'"$languageNameProper"'/g' "$3"
	sed -i 's/$languageName/'"$languageName"'/g' "$3"
}

#"$1" == languageName
#"$2" == languageNameProper
#"$3" == modSource (default, $blockly_orig)
#"$4" == modDestination  (default, "$scriptLocal"/templates/"$languageName")
_construct_generator_sequence() {
	_start
	_prepare_splice
	
	local localFunctionEntryPWD
	localFunctionEntryPWD="$PWD"
	
	local languageName
	languageName="$1"
	local languageNameProper
	languageNameProper="$2"
	
	#modSource == original files to modify
	export modSource="$blockly_orig"
	#export modSource="$SigBlockly_mod"
	export modDestination="$scriptLocal"/templates/"$languageName"
	
	[[ "$3" != "" ]] && export modSource="$3"
	[[ "$4" != "" ]] && export modDestination="$4"
	
	#Files.
	! mkdir -p "$modDestination" && _stop 1
	! mkdir -p "$modDestination"/demos/code && _stop 1
	! mkdir -p "$modDestination"/generators && _stop 1
	
	_modTransfer "$modSource" "$modDestination" build.py
	
	_modTransfer "$modSource" "$modDestination" demos/code/index.html
	_modTransfer "$modSource" "$modDestination" demos/code/code.js
	
	_modTransfer "$modSource" "$modDestination" "$generatorSource"/
	_modTransfer "$modSource" "$modDestination" "$generatorSource".js
	
	mv "$modDestination"/"$generatorSource" "$modDestination"/generators/"$languageName"
	mv "$modDestination"/"$generatorSource".js "$modDestination"/generators/"$languageName".js
	
	#Splice.
	_modTransfer "$spliceGitdiff" "$spliceTmpGitdiff" .
	
	_splice_generator_filter "$languageName" "$languageNameProper" "$spliceTmpGitdiff"/language/build.py.patch
	_splice_generator_filter "$languageName" "$languageNameProper" "$spliceTmpGitdiff"/language/demos/code/code.js.patch
	_splice_generator_filter "$languageName" "$languageNameProper" "$spliceTmpGitdiff"/language/demos/code/index.html.patch
	
	#Track.
	! cd "$modDestination"/ && _stop 1
	! git check-ignore . && _stop 1
	
	_gitNew
	
	#Substitute.
	sed -i 's/Blockly.Generator('\'''"$modLanguageNameProper"''\'')/Blockly.Generator('\'''"$languageName"''\'')/g' "$modDestination"/generators/"$languageName".js
	sed -i 's/Blockly\.'"$modLanguageNameProper"'/Blockly\.'"$languageName"'/g' "$modDestination"/generators/"$languageName".js
	
	find "$modDestination"/generators/"$languageName" -name '*.js' -exec sed -i 's/Blockly\.'"$modLanguageNameProper"'/Blockly\.'"$languageName"'/g' {} \;
	
	#Patch.
	#git apply "$spliceTmpGitdiff"/language/build.py.patch
	#git apply "$spliceTmpGitdiff"/language/demos/code/code.js.patch
	#git apply "$spliceTmpGitdiff"/language/demos/code/index.html.patch
	patch -p1 < "$spliceTmpGitdiff"/language/build.py.patch
	patch -p1 < "$spliceTmpGitdiff"/language/demos/code/code.js.patch
	patch -p1 < "$spliceTmpGitdiff"/language/demos/code/index.html.patch
	
	
	cd "$localFunctionEntryPWD"
	
	
	_stop
}

_construct_generator() {
	"$scriptAbsoluteLocation" _construct_generator_sequence "$@"
}

_construct_generator_c() {
	_construct_generator "c" "C" "$@"
}

_augment_generator_c() {
	[[ -e "$scriptLocal"/templates/c ]] && return 1
	
	if ! _construct_generator_c "$SigBlockly_mod"
	then
		return 1
	fi
	
	rsync -avx --exclude "/.git" "$scriptLocal"/templates/c/. "$SigBlockly_mod"/
}

_construct_generator_bash() {
	_construct_generator "bash" "BASH" "$@"
}

_augment_generator_bash() {
	[[ -e "$scriptLocal"/templates/bash ]] && return 1
	
	if ! _construct_generator_bash "$SigBlockly_mod"
	then
		return 1
	fi
	
	rsync -avx --exclude "/.git" "$scriptLocal"/templates/bash/. "$SigBlockly_mod"/
}

_construct() {
	[[ -e "$scriptLocal"/templates/c ]] && return 1
	[[ -e "$scriptLocal"/templates/bash ]] && return 1
	
	_construct_generator_c
	_construct_generator_bash
}

_augment() {
	[[ -e "$scriptLocal"/templates/c ]] && return 1
	[[ -e "$scriptLocal"/templates/bash ]] && return 1
	
	_augment_generator_c
	_augment_generator_bash
}

#duplicate _anchor
_refresh_anchors() {
	#_refresh_anchors_ubiquitous
	
	#cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_construct
	#cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_augment
	
	cp -a "$scriptAbsoluteFolder"/_anchor "$scriptAbsoluteFolder"/_refresh_overlay
}


#####Program

#Typically launches an application - ie. through virtualized container.
_launch() {
	false
	#"$@"
}

#Typically gathers command/variable scripts from other (ie. yaml) file types (ie. AppImage recipes).
_collect() {
	false
}

#Typical program entry point, absent any instancing support.
_enter() {
	_launch "$@"
}

#Typical program entry point.
_main() {
	_start
	
	_collect
	
	_enter "$@"
	
	_stop
}

#####Network Specific Variables
#Statically embedded into monolithic ubiquitous_bash.sh/cautossh script by compile .

# WARNING Must use unique netName!
export netName=default
export gatewayName=gw-"$netName"
export LOCALSSHPORT=22

#Network Defaults
export AUTOSSH_FIRST_POLL=45
export AUTOSSH_POLL=45
#export AUTOSSH_GATETIME=0
export AUTOSSH_GATETIME=15

#export AUTOSSH_PORT=0

#export AUTOSSH_DEBUG=1
#export AUTOSSH_LOGLEVEL=7

#Example ONLY. Modify port asignments.
_get_reversePorts() {
	export matchingReversePorts
	matchingReversePorts=()
	export matchingEMBEDDED=false
	
	local matched
	
	local testHostname
	testHostname="$1"
	[[ "$testHostname" == "" ]] && testHostname=$(hostname -s)
	
	if [[ "$testHostname" == "alpha" ]]
	then
		matchingReversePorts+=( "20000" )
		
		matched=true
	fi
	
	if [[ "$testHostname" == "beta" ]]
	then
		matchingReversePorts+=( "20001" )
		export matchingEMBEDDED=true
		
		matched=true
	fi
	
	if ! [[ "$matched" == "true" ]] || [[ "$testHostname" == '*' ]]
	then
		matchingReversePorts+=( "20009" )
		matchingReversePorts+=( "20008" )
	fi
	
	export matchingReversePorts
}

_get_reversePorts
export reversePorts=("${matchingReversePorts[@]}")
export EMBEDDED="$matchingEMBEDDED"

export keepKeys_SSH=true


_findUbiquitous() {
	export ubiquitiousLibDir="$scriptAbsoluteFolder"
	
	local scriptBasename=$(basename "$scriptAbsoluteFolder")
	if [[ "$scriptBasename" == "ubiquitous_bash" ]]
	then
		return 0
	fi
	
	if [[ -e "$ubiquitiousLibDir"/_lib/ubiquitous_bash ]]
	then
		export ubiquitiousLibDir="$ubiquitiousLibDir"/_lib/ubiquitous_bash
		return 0
	fi
	
	local ubiquitiousLibDirDiscovery=$(find ./_lib -maxdepth 3 -type d -name 'ubiquitous_bash' | head -n 1)
	if [[ "$ubiquitiousLibDirDiscovery" != "" ]] && [[ -e "$ubiquitiousLibDirDiscovery" ]]
	then
		export ubiquitiousLibDir="$ubiquitiousLibDirDiscovery"
		return 0
	fi
	
	return 1
}


_init_deps() {
	export enUb_set="true"
	
	export enUb_machineinfo=""
	export enUb_git=""
	export enUb_bup=""
	export enUb_notLean=""
	export enUb_build=""
	export enUb_os_x11=""
	export enUb_proxy=""
	export enUb_proxy_special=""
	export enUb_x11=""
	export enUb_blockchain=""
	export enUb_image=""
	export enUb_virt=""
	export enUb_ChRoot=""
	export enUb_QEMU=""
	export enUb_vbox=""
	export enUb_docker=""
	export enUb_wine=""
	export enUb_DosBox=""
	export enUb_msw=""
	export enUb_fakehome=""
	export enUb_abstractfs=""
	export enUb_buildBash=""
	export enUb_buildBashUbiquitous=""
	
	export enUb_command=""
	export enUb_synergy=""
	
	export enUb_hardware=""
	export enUb_enUb_x220t=""
	
	export enUb_user=""
}


_deps_machineinfo() {
	export enUb_machineinfo="true"
}

_deps_git() {
	export enUb_git="true"
}

_deps_bup() {
	export enUb_bup="true"
}

_deps_notLean() {
	_deps_git
	_deps_bup
	export enUb_notLean="true"
}

_deps_build() {
	export enUb_build="true"
}

#Note that '_build_bash' does not incur '_build', expected to require only scripted concatenation.
_deps_build_bash() {
	export enUb_buildBash="true"
}

_deps_build_bash_ubiquitous() {
	_deps_build_bash
	export enUb_buildBashUbiquitous="true"
}

_deps_os_x11() {
	export enUb_os_x11="true"
}

_deps_proxy() {
	export enUb_proxy="true"
}

_deps_proxy_special() {
	_deps_proxy
	export enUb_proxy_special="true"
}

_deps_x11() {
	_deps_build
	_deps_notLean
	export enUb_x11="true"
}

_deps_blockchain() {
	_deps_notLean
	_deps_x11
	export enUb_blockchain="true"
}

_deps_image() {
	_deps_notLean
	_deps_machineinfo
	export enUb_image="true"
}

_deps_virt() {
	_deps_build
	_deps_notLean
	_deps_machineinfo
	_deps_image
	export enUb_virt="true"
}

_deps_chroot() {
	_deps_notLean
	_deps_virt
	export enUb_ChRoot="true"
}

_deps_qemu() {
	_deps_notLean
	_deps_virt
	export enUb_QEMU="true"
}

_deps_vbox() {
	_deps_notLean
	_deps_virt
	export enUb_vbox="true"
}

_deps_docker() {
	_deps_notLean
	_deps_virt
	export enUb_docker="true"
}

_deps_wine() {
	_deps_notLean
	_deps_virt
	export enUb_wine="true"
}

_deps_dosbox() {
	_deps_notLean
	_deps_virt
	export enUb_DosBox="true"
}

_deps_msw() {
	_deps_notLean
	_deps_virt
	_deps_qemu
	_deps_vbox
	_deps_wine
	export enUb_msw="true"
}

_deps_fakehome() {
	_deps_notLean
	_deps_virt
	export enUb_fakehome="true"
}

_deps_abstractfs() {
	_deps_notLean
	_deps_virt
	export enUb_abstractfs="true"
}

_deps_command() {
	_deps_os_x11
	_deps_proxy
	_deps_proxy_special
	
	export enUb_command="true"
}

_deps_synergy() {
	_deps_command
	export enUb_synergy="true"
}

_deps_hardware() {
	_deps_notLean
	export enUb_hardware="true"
}

_deps_x220t() {
	_deps_notLean
	_deps_hardware
	export enUb_x220t="true"
}

_deps_user() {
	_deps_notLean
	export enUb_user="true"
}


_generate_bash() {
	
	_findUbiquitous
	_vars_generate_bash
	
	#####
	
	_deps_build_bash
	_deps_build_bash_ubiquitous
	
	#####
	
	rm -f "$progScript" >/dev/null 2>&1
	
	_compile_bash_header
	
	_compile_bash_essential_utilities
	_compile_bash_utilities
	
	_compile_bash_vars_global
	
	_compile_bash_selfHost
	
	_compile_bash_overrides
	
	_includeScripts "${includeScriptList[@]}"
	
	#Default command.
	echo >> "$progScript"
	echo '_generate_compile_bash "$@"' >> "$progScript"
	echo 'exit 0' >> "$progScript"
	
	chmod u+x "$progScript"
	
	# DANGER Do NOT remove.
	exit 0
}

_vars_generate_bash() {
	export configDir="$scriptAbsoluteFolder"/_config
	
	export progDir="$scriptAbsoluteFolder"/_prog
	export progScript="$scriptAbsoluteFolder"/compile.sh
}

#Intended as last command in a compile script. Updates the compile script itself, uses the updated script to update itself again, then compiles product with fully synchronized script.
# WARNING Must be last command and part of a function, or there will be risk of re-entering the script at an incorrect location.
_generate_compile_bash() {
	"$scriptAbsoluteLocation" _generate_bash
	"$scriptAbsoluteFolder"/compile.sh _generate_bash
	"$scriptAbsoluteFolder"/compile.sh _compile_bash
	
	[[ "$objectName" == "ubiquitous_bash" ]] && "$scriptAbsoluteFolder"/compile.sh _compile_bash lean lean.sh
	
	[[ "$1" != "" ]] && "$scriptAbsoluteFolder"/compile.sh _compile_bash "$@"
	
	_generate_compile_bash_prog
	
	# DANGER Do NOT remove.
	exit 0
}

# #No production use. Unmaintained, obsolete. Never used literally. Preserved as an example command set to build the otherwise self-hosted generate/compile script manually (ie. bootstrapping).
# _bootstrap_bash_basic() {
# 	cat "generic"/minimalheader.sh "labels"/utilitiesLabel.sh "generic/filesystem"/absolutepaths.sh "generic/filesystem"/safedelete.sh "generic/process"/timeout.sh "generic"/uid.sh "generic/filesystem/permissions"/checkpermissions.sh "build/bash"/include.sh "structure"/globalvars.sh "build/bash/ubiquitous"/discoverubiquitious.sh "build/bash/ubiquitous"/depsubiquitous.sh "build/bash"/generate.sh "build/bash"/compile.sh "structure"/overrides.sh > ./compile.sh
# 	echo >> ./compile.sh
# 	echo _generate_compile_bash >> ./compile.sh
# 	chmod u+x ./compile.sh
# }

_generate_compile_bash_prog() {
	"$scriptAbsoluteLocation" _true
	
	rm "$scriptAbsoluteFolder"/ubiquitous_bash.sh
	
	#"$scriptAbsoluteLocation" _compile_bash cautossh cautossh
	#"$scriptAbsoluteLocation" _compile_bash lean lean.sh
	
	"$scriptAbsoluteLocation" _compile_bash core ubiquitous_bash.sh
	
	#"$scriptAbsoluteLocation" _compile_bash "" ""
	#"$scriptAbsoluteLocation" _compile_bash ubiquitous_bash ubiquitous_bash.sh
	
	#"$scriptAbsoluteLocation" _package
}

#Default is to include all, or run a specified configuration. For this reason, it will be more typical to override this entire function, rather than append any additional code.
_compile_bash_deps() {
	[[ "$1" == "lean" ]] && return 0
	
	if [[ "$1" == "cautossh" ]]
	then
		_deps_os_x11
		_deps_proxy
		_deps_proxy_special
		
		_deps_git
		_deps_bup
		
		_deps_command
		_deps_synergy
		
		return 0
	fi
	
	if [[ "$1" == "core" ]]
	then
		_deps_notLean
		_deps_os_x11
		
		_deps_x11
		_deps_image
		_deps_virt
		_deps_chroot
		_deps_qemu
		_deps_vbox
		#_deps_docker
		_deps_wine
		_deps_dosbox
		_deps_msw
		_deps_fakehome
		_deps_abstractfs
		
		_deps_git
		_deps_bup
		
		#_deps_blockchain
		
		#_deps_command
		#_deps_synergy
		
		#_deps_hardware
		#_deps_x220t
		
		#_deps_user
		
		#_deps_proxy
		#_deps_proxy_special
		
		_deps_build
		
		_deps_build_bash
		_deps_build_bash_ubiquitous
		
		return 0
	fi
	
	if [[ "$1" == "" ]] || [[ "$1" == "ubiquitous_bash" ]] || [[ "$1" == "ubiquitous_bash.sh" ]] || [[ "$1" == "complete" ]]
	then
		_deps_notLean
		_deps_os_x11
		
		_deps_x11
		_deps_image
		_deps_virt
		_deps_chroot
		_deps_qemu
		_deps_vbox
		_deps_docker
		_deps_wine
		_deps_dosbox
		_deps_msw
		_deps_fakehome
		_deps_abstractfs
		
		_deps_git
		_deps_bup
		
		_deps_blockchain
		
		_deps_command
		_deps_synergy
		
		_deps_hardware
		_deps_x220t
		
		_deps_user
		
		_deps_proxy
		_deps_proxy_special
		
		_deps_build
		
		_deps_build_bash
		_deps_build_bash_ubiquitous
		
		return 0
	fi
	
	return 1
}

_vars_compile_bash() {
	export configDir="$scriptAbsoluteFolder"/_config
	
	export progDir="$scriptAbsoluteFolder"/_prog
	export progScript="$scriptAbsoluteFolder"/ubiquitous_bash.sh
	[[ "$1" != "" ]] && export progScript="$scriptAbsoluteFolder"/"$1"
	
	_vars_compile_bash_prog "$@"
}

_compile_bash_header() {
	export includeScriptList
	
	includeScriptList+=( "generic"/minimalheader.sh )
	includeScriptList+=( "generic"/ubiquitousheader.sh )
	
	includeScriptList+=( "os/override"/override.sh )
	includeScriptList+=( "os/override"/override_prog.sh )
}

_compile_bash_header_program() {
	export includeScriptList
	
	includeScriptList+=( progheader.sh )
}

_compile_bash_essential_utilities() {
	export includeScriptList
	
	#####Essential Utilities
	includeScriptList+=( "labels"/utilitiesLabel.sh )
	includeScriptList+=( "generic/filesystem"/absolutepaths.sh )
	includeScriptList+=( "generic/filesystem"/safedelete.sh )
	includeScriptList+=( "generic/process"/timeout.sh )
	includeScriptList+=( "generic/process"/terminate.sh )
	includeScriptList+=( "generic"/uid.sh )
	includeScriptList+=( "generic/filesystem/permissions"/checkpermissions.sh )
	includeScriptList+=( "generic"/findInfrastructure.sh )
	includeScriptList+=( "generic"/gather.sh )
	
	includeScriptList+=( "generic/filesystem"/internal.sh )
	
	includeScriptList+=( "generic"/messaging.sh )
	
	includeScriptList+=( "generic"/config/mustcarry.sh )
	
	[[ "$enUb_buildBash" == "true" ]] && includeScriptList+=( "build/bash"/include_bash.sh )
}

_compile_bash_utilities() {
	export includeScriptList
	
	#####Utilities
	includeScriptList+=( "generic/filesystem"/getext.sh )
	
	includeScriptList+=( "generic/filesystem"/finddir.sh )
	
	includeScriptList+=( "generic/filesystem"/discoverresource.sh )
	
	includeScriptList+=( "generic/filesystem"/relink.sh )
	
	[[ "$enUb_notLean" == "true" ]] && includeScriptList+=( "generic/filesystem/mounts"/bindmountmanager.sh )
	
	includeScriptList+=( "generic/filesystem/mounts"/waitumount.sh )
	
	includeScriptList+=( "generic/filesystem/mounts"/mountchecks.sh )
	
	includeScriptList+=( "generic/process"/waitforprocess.sh )
	
	includeScriptList+=( "generic/process"/daemon.sh )
	
	includeScriptList+=( "generic/process"/remotesig.sh )
	
	includeScriptList+=( "generic/process"/embed_here.sh )
	includeScriptList+=( "generic/process"/embed.sh )
	
	includeScriptList+=( "generic/net"/fetch.sh )
	
	includeScriptList+=( "generic/net"/findport.sh )
	
	includeScriptList+=( "generic/net"/waitport.sh )
	
	[[ "$enUb_proxy_special" == "true" ]] && includeScriptList+=( "generic/net/proxy/tor"/tor.sh )
	
	[[ "$enUb_proxy" == "true" ]] && includeScriptList+=( "generic/net/proxy/ssh"/here_ssh.sh )
	[[ "$enUb_proxy" == "true" ]] && includeScriptList+=( "generic/net/proxy/ssh"/ssh.sh )
	[[ "$enUb_proxy" == "true" ]] && includeScriptList+=( "generic/net/proxy/ssh"/autossh.sh )
	
	[[ "$enUb_proxy" == "true" ]] && includeScriptList+=( "generic/net/proxy/proxyrouter"/here_proxyrouter.sh )
	[[ "$enUb_proxy" == "true" ]] && includeScriptList+=( "generic/net/proxy/proxyrouter"/proxyrouter.sh )
	
	includeScriptList+=( "generic"/showCommand.sh )
	includeScriptList+=( "generic"/validaterequest.sh )
	
	includeScriptList+=( "generic"/preserveLog.sh )
	
	[[ "$enUb_os_x11" == "true" ]] && includeScriptList+=( "os/unix/x11"/findx11.sh )
	
	includeScriptList+=( "os"/getDep.sh )
	[[ "$enUb_notLean" == "true" ]] && includeScriptList+=( "os/distro/debian"/getDep_debian.sh )
	
	[[ "$enUb_notLean" == "true" ]] && includeScriptList+=( "os/unix/systemd"/here_systemd.sh )
	[[ "$enUb_notLean" == "true" ]] && includeScriptList+=( "os/unix/systemd"/hook_systemd.sh )
	
	includeScriptList+=( "special"/mustberoot.sh )
	includeScriptList+=( "special"/mustgetsudo.sh )
	
	[[ "$enUb_notLean" == "true" ]] && includeScriptList+=( "special/gosu"/gosu.sh )
	
	includeScriptList+=( "special"/uuid.sh )
	
	[[ "$enUb_notLean" == "true" ]] && includeScriptList+=( "instrumentation"/bashdb/bashdb.sh )
	[[ "$enUb_notLean" == "true" ]] && includeScriptList+=( "instrumentation"/profiling/stopwatch.sh )
}

_compile_bash_utilities_virtualization() {
	export includeScriptList
	
	[[ "$enUb_virt" == "true" ]] && includeScriptList+=( "virtualization"/virtenv.sh )
	
	[[ "$enUb_virt" == "true" ]] && includeScriptList+=( "virtualization"/findInfrastructure_virt.sh )
	
	[[ "$enUb_virt" == "true" ]] && includeScriptList+=( "virtualization"/osTranslation.sh )
	[[ "$enUb_virt" == "true" ]] && includeScriptList+=( "virtualization"/localPathTranslation.sh )
	
	[[ "$enUb_abstractfs" == "true" ]] && includeScriptList+=( "virtualization/abstractfs"/abstractfs.sh )
	[[ "$enUb_abstractfs" == "true" ]] && includeScriptList+=( "virtualization/abstractfs"/abstractfsvars.sh )
	
	[[ "$enUb_fakehome" == "true" ]] && includeScriptList+=( "virtualization/fakehome"/fakehomemake.sh )
	[[ "$enUb_fakehome" == "true" ]] && includeScriptList+=( "virtualization/fakehome"/fakehome.sh )
	[[ "$enUb_fakehome" == "true" ]] && includeScriptList+=( "virtualization/fakehome"/fakehomeuser.sh )
	includeScriptList+=( "virtualization/fakehome"/fakehomereset.sh )
	
	[[ "$enUb_image" == "true" ]] && includeScriptList+=( "virtualization/image"/mountimage.sh )
	[[ "$enUb_image" == "true" ]] && includeScriptList+=( "virtualization/image"/createImage.sh )
	[[ "$enUb_image" == "true" ]] && includeScriptList+=( "virtualization/image"/here_bootdisc.sh )
	[[ "$enUb_image" == "true" ]] && includeScriptList+=( "virtualization/image"/bootdisc.sh )
	[[ "$enUb_image" == "true" ]] && includeScriptList+=( "virtualization/image"/userpersistenthome.sh )
	[[ "$enUb_image" == "true" ]] && includeScriptList+=( "virtualization/image"/transferimage.sh )
	
	[[ "$enUb_ChRoot" == "true" ]] && includeScriptList+=( "virtualization/chroot"/testchroot.sh )
	
	[[ "$enUb_ChRoot" == "true" ]] && includeScriptList+=( "virtualization/chroot"/procchroot.sh )
	[[ "$enUb_ChRoot" == "true" ]] && includeScriptList+=( "virtualization/chroot"/mountchroot.sh )
	[[ "$enUb_ChRoot" == "true" ]] && includeScriptList+=( "virtualization/chroot"/enterchroot.sh )
	
	[[ "$enUb_ChRoot" == "true" ]] && includeScriptList+=( "virtualization/chroot"/mountchrootuser.sh )
	[[ "$enUb_ChRoot" == "true" ]] && includeScriptList+=( "virtualization/chroot"/userchroot.sh )
	[[ "$enUb_ChRoot" == "true" ]] && includeScriptList+=( "virtualization/chroot"/dropchroot.sh )
	
	[[ "$enUb_QEMU" == "true" ]] && includeScriptList+=( "virtualization/qemu"/qemu-raspi-raspi.sh )
	[[ "$enUb_QEMU" == "true" ]] && includeScriptList+=( "virtualization/qemu"/qemu-x64-raspi.sh )
	[[ "$enUb_QEMU" == "true" ]] && includeScriptList+=( "virtualization/qemu"/qemu-x64-x64.sh )
	[[ "$enUb_QEMU" == "true" ]] && includeScriptList+=( "virtualization/qemu"/qemu.sh )
	
	[[ "$enUb_vbox" == "true" ]] && includeScriptList+=( "virtualization/vbox"/vboxtest.sh )
	[[ "$enUb_vbox" == "true" ]] && includeScriptList+=( "virtualization/vbox"/vboxmount.sh )
	[[ "$enUb_vbox" == "true" ]] && includeScriptList+=( "virtualization/vbox"/vboxlab.sh )
	[[ "$enUb_vbox" == "true" ]] && includeScriptList+=( "virtualization/vbox"/vboxuser.sh )
	
	[[ "$enUb_DosBox" == "true" ]] && includeScriptList+=( "virtualization/dosbox"/here_dosbox.sh )
	[[ "$enUb_DosBox" == "true" ]] && includeScriptList+=( "virtualization/dosbox"/dosbox.sh )
	
	[[ "$enUb_wine" == "true" ]] && includeScriptList+=( "virtualization/wine"/wine.sh )
	
	[[ "$enUb_docker" == "true" ]] && includeScriptList+=( "virtualization/docker"/here_docker.sh )
	[[ "$enUb_docker" == "true" ]] && includeScriptList+=( "virtualization/docker"/dockerdrop.sh )
	[[ "$enUb_docker" == "true" ]] && includeScriptList+=( "virtualization/docker"/dockertest.sh )
	[[ "$enUb_docker" == "true" ]] && includeScriptList+=( "virtualization/docker"/dockerchecks.sh )
	[[ "$enUb_docker" == "true" ]] && includeScriptList+=( "virtualization/docker"/dockeruser.sh )
}

_compile_bash_shortcuts() {
	export includeScriptList
	
	
	#####Shortcuts
	includeScriptList+=( "labels"/shortcutsLabel.sh )
	
	includeScriptList+=( "shortcuts/prompt"/visualPrompt.sh )
	
	[[ "$enUb_notLean" == "true" ]] && includeScriptList+=( "shortcuts/dev"/devsearch.sh )
	
	[[ "$enUb_fakehome" == "true" ]] && [[ "$enUb_notLean" == "true" ]] && includeScriptList+=( "shortcuts/dev/app"/devemacs.sh )
	[[ "$enUb_fakehome" == "true" ]] && [[ "$enUb_notLean" == "true" ]] && includeScriptList+=( "shortcuts/dev/app"/devatom.sh )
	[[ "$enUb_fakehome" == "true" ]] && [[ "$enUb_abstractfs" == "true" ]] && [[ "$enUb_notLean" == "true" ]] && includeScriptList+=( "shortcuts/dev/app"/deveclipse.sh )
	
	[[ "$enUb_notLean" == "true" ]] && includeScriptList+=( "shortcuts/dev/scope"/devscope.sh )
	[[ "$enUb_notLean" == "true" ]] && includeScriptList+=( "shortcuts/dev/scope"/devscope_here.sh )
	
	# WARNING: Some apps may have specific dependencies (eg. fakeHome, abstractfs, eclipse, atom).
	[[ "$enUb_notLean" == "true" ]] && includeScriptList+=( "shortcuts/dev/scope"/devscope_app.sh )
	
	[[ "$enUb_git" == "true" ]] && includeScriptList+=( "shortcuts/git"/git.sh )
	[[ "$enUb_git" == "true" ]] && includeScriptList+=( "shortcuts/git"/gitBare.sh )
	
	[[ "$enUb_bup" == "true" ]] && includeScriptList+=( "shortcuts/bup"/bup.sh )
	
	[[ "$enUb_image" == "true" ]] && includeScriptList+=( "shortcuts/mkboot"/here_mkboot.sh )
	[[ "$enUb_image" == "true" ]] && includeScriptList+=( "shortcuts/mkboot"/mkboot.sh )
	
	[[ "$enUb_notLean" == "true" ]] && includeScriptList+=( "shortcuts/distro"/distro.sh )
	
	[[ "$enUb_QEMU" == "true" ]] && includeScriptList+=( "shortcuts/distro/debian"/createDebian.sh )
	[[ "$enUb_image" == "true" ]] && includeScriptList+=( "shortcuts/distro/raspbian"/createRaspbian.sh )
	
	[[ "$enUb_msw" == "true" ]] && includeScriptList+=( "shortcuts/distro/msw"/msw.sh )
	
	[[ "$enUb_x11" == "true" ]] && includeScriptList+=( "shortcuts/x11"/testx11.sh )
	[[ "$enUb_x11" == "true" ]] && includeScriptList+=( "shortcuts/x11"/xinput.sh )
	[[ "$enUb_x11" == "true" ]] && includeScriptList+=( "shortcuts/x11/clipboard"/x11ClipboardImage.sh )
	
	[[ "$enUb_x11" == "true" ]] && includeScriptList+=( "shortcuts/x11/desktop/kde4x"/kde4x.sh )
	
	[[ "$enUb_vbox" == "true" ]] && includeScriptList+=( "shortcuts/vbox"/vboxconvert.sh )
	
	[[ "$enUb_docker" == "true" ]] && includeScriptList+=( "shortcuts/docker"/dockerassets.sh )
	[[ "$enUb_docker" == "true" ]] && includeScriptList+=( "shortcuts/docker"/dockerdelete.sh )
	[[ "$enUb_docker" == "true" ]] && includeScriptList+=( "shortcuts/docker"/dockercreate.sh )
	[[ "$enUb_docker" == "true" ]] && includeScriptList+=( "shortcuts/docker"/dockerconvert.sh )
	[[ "$enUb_docker" == "true" ]] && includeScriptList+=( "shortcuts/docker"/dockerportation.sh )
	[[ "$enUb_docker" == "true" ]] && includeScriptList+=( "shortcuts/docker"/dockercontainer.sh )
	
	[[ "$enUb_docker" == "true" ]] && includeScriptList+=( "shortcuts/docker"/dockercontainer.sh )
	
	[[ "$enUb_image" == "true" ]] && includeScriptList+=( "shortcuts/image"/gparted.sh )
}

_compile_bash_shortcuts_setup() {
	export includeScriptList
	
	includeScriptList+=( "shortcuts"/setupUbiquitous_here.sh )
	includeScriptList+=( "shortcuts"/setupUbiquitous.sh )
}

_compile_bash_bundled() {
	export includeScriptList
	
	
	[[ "$enUb_blockchain" == "true" ]] && includeScriptList+=( "blockchain"/blockchain.sh )
	[[ "$enUb_blockchain" == "true" ]] && includeScriptList+=( "blockchain/ethereum"/ethereum.sh )
	[[ "$enUb_blockchain" == "true" ]] && includeScriptList+=( "shortcuts/blockchain/ethereum"/ethereum.sh )
	
	[[ "$enUb_blockchain" == "true" ]] && includeScriptList+=( "blockchain/ethereum"/ethereum_parity.sh )
}

_compile_bash_command() {
	[[ "$enUb_command" == "true" ]] && includeScriptList+=( "generic/net/command"/command.sh )
	
	[[ "$enUb_command" == "true" ]] && [[ "$enUb_synergy" == "true" ]] && includeScriptList+=( "generic/net/command/synergy"/here_synergy.sh )
	[[ "$enUb_command" == "true" ]] && [[ "$enUb_synergy" == "true" ]] && includeScriptList+=( "generic/net/command/synergy"/synergy.sh )
}

_compile_bash_user() {
	true
}

_compile_bash_hardware() {
	[[ "$enUb_hardware" == "true" ]] && [[ "$enUb_x220t" == "true" ]] && includeScriptList+=( "hardware/x220t"/x220_display.sh )
}

_compile_bash_vars_basic() {
	export includeScriptList
	
	
	#####Basic Variable Management
	includeScriptList+=( "labels"/basicvarLabel.sh )
}

_compile_bash_vars_global() {
	export includeScriptList
	
	
	#####Global variables.
	includeScriptList+=( "structure"/globalvars.sh )
}

_compile_bash_vars_spec() {
	export includeScriptList
	
	
	[[ "$enUb_machineinfo" == "true" ]] && includeScriptList+=( "special/machineinfo"/machinevars.sh )
	
	[[ "$enUb_virt" == "true" ]] && includeScriptList+=( "virtualization"/virtvars.sh )
	[[ "$enUb_virt" == "true" ]] && includeScriptList+=( "virtualization"/image/imagevars.sh )
	
	[[ "$enUb_proxy" == "true" ]] && includeScriptList+=( "generic/net/proxy/ssh"/sshvars.sh )
	
	
	includeScriptList+=( "structure"/specglobalvars.sh )
}

_compile_bash_vars_shortcuts() {
	export includeScriptList
	
	includeScriptList+=( "shortcuts/git"/gitVars.sh )
}

_compile_bash_vars_virtualization() {
	export includeScriptList
	
	
	[[ "$enUb_fakehome" == "true" ]] && includeScriptList+=( "virtualization/fakehome"/fakehomevars.sh )
	[[ "$enUb_vbox" == "true" ]] && includeScriptList+=( "virtualization/vbox"/vboxvars.sh )
	[[ "$enUb_docker" == "true" ]] && includeScriptList+=( "virtualization/docker"/dockervars.sh )
}

_compile_bash_vars_bundled() {
	export includeScriptList
	
	
	[[ "$enUb_proxy" == "true" ]] && includeScriptList+=( "generic/net/proxy/ssh"/sshvars.sh )
}

_compile_bash_buildin() {
	export includeScriptList
	
	[[ "$enUb_build" == "true" ]] && includeScriptList+=( "generic/hello"/hello.sh )
	[[ "$enUb_build" == "true" ]] && [[ "$enUb_notLean" == "true" ]] && includeScriptList+=( "generic/process"/idle.sh )
	
	[[ "$enUb_build" == "true" ]] && includeScriptList+=( "structure"/build.sh )
}

_compile_bash_environment() {
	export includeScriptList
	
	
	includeScriptList+=( "structure"/localfs.sh )
	
	includeScriptList+=( "structure"/localenv.sh )
}

_compile_bash_installation() {
	export includeScriptList
	
	includeScriptList+=( "structure"/installation.sh )
	includeScriptList+=( "structure"/installation_prog.sh )
}

_compile_bash_program() {
	export includeScriptList
	
	
	includeScriptList+=( core.sh )
	
	includeScriptList+=( "structure"/program.sh )
}

_compile_bash_config() {
	export includeScriptList
	
	
	#####Hardcoded
	includeScriptList+=( netvars.sh )
}

_compile_bash_selfHost() {
	export includeScriptList
	
	
	#####Generate/Compile
	[[ "$enUb_buildBashUbiquitous" == "true" ]] && includeScriptList+=( "build/bash/ubiquitous"/discoverubiquitious.sh )
	[[ "$enUb_buildBashUbiquitous" == "true" ]] && includeScriptList+=( "build/bash/ubiquitous"/depsubiquitous.sh )
	[[ "$enUb_buildBashUbiquitous" == "true" ]] && includeScriptList+=( deps.sh )
	[[ "$enUb_buildBashUbiquitous" == "true" ]] && includeScriptList+=( "build/bash"/generate_bash.sh )
	[[ "$enUb_buildBashUbiquitous" == "true" ]] && includeScriptList+=( "build/bash"/generate_bash_prog.sh )
	
	[[ "$enUb_buildBashUbiquitous" == "true" ]] && includeScriptList+=( "build/bash"/compile_bash.sh )
	[[ "$enUb_buildBashUbiquitous" == "true" ]] && includeScriptList+=( "build/bash"/compile_bash_prog.sh )
}

_compile_bash_overrides() {
	export includeScriptList
	
	
	includeScriptList+=( "structure"/overrides.sh )
}

_compile_bash_entry() {
	export includeScriptList
	
	
	includeScriptList+=( "structure"/entry.sh )
}

#Ubiquitous Bash compile script. Override with "ops", "_config", or "_prog" directives through "compile_bash_prog.sh" to compile other work products through similar scripting.
# "$1" == configuration
# "$2" == output filename
# DANGER
#Especially, be careful to explicitly check all prerequsites for _safeRMR are in place.
# DANGER
# Intended only for manual use, or within a memory cached function terminated by "exit". Launching through "$scriptAbsoluteLocation" is not adequate protection if the original script itself can reach modified code!
# However, launching through "$scriptAbsoluteLocation" can be used to run a command within the new version fo the script. Use this capability only with full understanding of this notification. 
# WARNING
#Beware lean configurations may not have been properly tested, and are of course intended for developer use. Their purpose is to disable irrelevant dependency checking in "_test" procedures. Rigorous test procedures covering all intended functionality should always be included in downstream projects. Pull requests welcome.
_compile_bash() {
	_findUbiquitous
	_vars_compile_bash "$2"
	
	#####
	
	_compile_bash_deps "$1"
	_compile_bash_deps_prog "$1"
	
	#####
	
	rm "$progScript" >/dev/null 2>&1
	
	export includeScriptList
	
	_compile_bash_header
	_compile_bash_header_prog
	_compile_bash_header_program
	_compile_bash_header_program_prog
	
	_compile_bash_essential_utilities
	_compile_bash_essential_utilities_prog
	_compile_bash_utilities
	_compile_bash_utilities_prog
	_compile_bash_utilities_virtualization
	_compile_bash_utilities_virtualization_prog
	
	_compile_bash_shortcuts
	_compile_bash_shortcuts_prog
	_compile_bash_shortcuts_setup
	_compile_bash_shortcuts_setup_prog
	
	_compile_bash_bundled
	_compile_bash_bundled_prog
	
	_compile_bash_command
	
	_compile_bash_user
	
	_compile_bash_hardware
	
	_compile_bash_vars_basic
	_compile_bash_vars_basic_prog
	_compile_bash_vars_global
	_compile_bash_vars_global_prog
	_compile_bash_vars_spec
	_compile_bash_vars_spec_prog
	
	_compile_bash_vars_shortcuts
	_compile_bash_vars_shortcuts_prog
	
	_compile_bash_vars_virtualization
	_compile_bash_vars_virtualization_prog
	_compile_bash_vars_bundled
	_compile_bash_vars_bundled_prog
	
	_compile_bash_buildin
	_compile_bash_buildin_prog
	
	
	_compile_bash_environment
	_compile_bash_environment_prog
	
	_compile_bash_installation
	_compile_bash_installation_prog
	
	_compile_bash_program
	_compile_bash_program_prog
	
	
	_compile_bash_config
	_compile_bash_config_prog
	
	_compile_bash_selfHost
	_compile_bash_selfHost_prog
	
	
	_compile_bash_overrides
	_compile_bash_overrides_prog
	
	_compile_bash_entry
	_compile_bash_entry_prog
	
	
	
	_includeScripts "${includeScriptList[@]}"
	
	chmod u+x "$progScript"
	
	#if "$progScript" _test > ./compile.log 2>&1
	#then
	#	rm compile.log
	#else
	#	exit 1
	#fi
	
	#"$progScript" _package
	
	# DANGER Do NOT remove.
	exit 0
}

_compile_bash_deps_prog() {
	true
}

# #Default is to include all, or run a specified configuration. For this reason, it will be more typical to override this entire function, rather than append any additional code.
# _compile_bash_deps() {
# 	[[ "$1" == "lean" ]] && return 0
# 	
# 	if [[ "$1" == "cautossh" ]]
# 	then
# 		_deps_os_x11
# 		_deps_proxy
# 		_deps_proxy_special
# 		
# 		return 0
# 	fi
# 	
# 	if [[ "$1" == "" ]]
# 	then
# 		_deps_notLean
# 		_deps_os_x11
# 		
# 		_deps_x11
# 		_deps_image
# 		_deps_virt
# 		_deps_chroot
# 		_deps_qemu
# 		_deps_vbox
# 		_deps_docker
# 		_deps_wine
# 		_deps_dosbox
# 		_deps_msw
# 		_deps_fakehome
# 		
# 		_deps_blockchain
# 		
# 		_deps_proxy
# 		_deps_proxy_special
#		
#		_deps_build
# 		
# 		_deps_build_bash
# 		_deps_build_bash_ubiquitous
# 		
# 		return 0
# 	fi
# }

_vars_compile_bash_prog() {
	#export configDir="$scriptAbsoluteFolder"/_config
	
	#export progDir="$scriptAbsoluteFolder"/_prog
	#export progScript="$scriptAbsoluteFolder"/ubiquitous_bash.sh
	#[[ "$1" != "" ]] && export progScript="$scriptAbsoluteFolder"/"$1"
	
	true
}

_compile_bash_header_prog() {	
	export includeScriptList
	true
}

_compile_bash_header_program_prog() {	
	export includeScriptList
	true
}

_compile_bash_essential_utilities_prog() {	
	export includeScriptList
	true
}

_compile_bash_utilities_virtualization_prog() {	
	export includeScriptList
	true
}

_compile_bash_utilities_prog() {	
	export includeScriptList
	true
}

_compile_bash_shortcuts_prog() {	
	export includeScriptList
	true
}

_compile_bash_shortcuts_setup_prog() {	
	export includeScriptList
	true
}

_compile_bash_bundled_prog() {	
	export includeScriptList
	true
}

_compile_bash_vars_basic_prog() {	
	export includeScriptList
	true
}

_compile_bash_vars_global_prog() {	
	export includeScriptList
	true
}

_compile_bash_vars_spec_prog() {	
	export includeScriptList
	true
}

_compile_bash_vars_shortcuts_prog() {	
	export includeScriptList
	true
}

_compile_bash_vars_virtualization_prog() {	
	export includeScriptList
	true
}

_compile_bash_vars_bundled_prog() {	
	export includeScriptList
	true
}

_compile_bash_buildin_prog() {	
	export includeScriptList
	true
}

_compile_bash_environment_prog() {	
	export includeScriptList
	true
}

_compile_bash_installation_prog() {	
	export includeScriptList
	true
}

_compile_bash_program_prog() {	
	export includeScriptList
	true
}

_compile_bash_config_prog() {	
	export includeScriptList
	true
}

_compile_bash_selfHost_prog() {	
	export includeScriptList
	true
}

_compile_bash_overrides_prog() {	
	export includeScriptList
	true
}

_compile_bash_entry_prog() {	
	export includeScriptList
	true
}

#####Overrides

[[ "$isDaemon" == "true" ]] && echo "$$" | _prependDaemonPID

#May allow traps to work properly in simple scripts which do not include more comprehensive "_stop" or "_stop_emergency" implementations.
if ! type _stop > /dev/null 2>&1
then
	_stop() {
		if [[ "$1" != "" ]]
		then
			exit "$1"
		else
			exit 0
		fi
	}
fi
if ! type _stop_emergency > /dev/null 2>&1
then
	_stop_emergency() {
		_stop "$1"
	}
fi

#Traps, if script is not imported into existing shell, or bypass requested.
# WARNING Exact behavior of this system is critical to some use cases.
if [[ "$ub_import" != "true" ]] || [[ "$ub_import_param" == "--bypass" ]]
then
	trap 'excode=$?; _stop $excode; trap - EXIT; echo $excode' EXIT HUP QUIT PIPE 	# reset
	trap 'excode=$?; trap "" EXIT; _stop $excode; echo $excode' EXIT HUP QUIT PIPE 	# ignore
	
	trap 'excode=$?; _stop_emergency $excode; trap - EXIT; echo $excode' INT TERM	# reset
	trap 'excode=$?; trap "" EXIT; _stop_emergency $excode; echo $excode' INT TERM	# ignore
fi

#Override functions with external definitions from a separate file if available.
#if [[ -e "./ops" ]]
#then
#	. ./ops
#fi

#Override functions with external definitions from a separate file if available.
if [[ -e "$objectDir"/ops ]]
then
	. "$objectDir"/ops
fi
if [[ -e "$scriptLocal"/ops ]]
then
	. "$scriptLocal"/ops
fi
if [[ -e "$scriptLocal"/ssh/ops ]]
then
	. "$scriptLocal"/ssh/ops
fi

#WILL BE OVERWRITTEN FREQUENTLY.
#Intended for automatically generated shell code identifying usable resources, such as unused network ports. Do NOT use for serialization of internal variables (use $varStore for that).
if [[ -e "$objectDir"/opsauto ]]
then
	. "$objectDir"/opsauto
fi
if [[ -e "$scriptLocal"/opsauto ]]
then
	. "$scriptLocal"/opsauto
fi
if [[ -e "$scriptLocal"/ssh/opsauto ]]
then
	. "$scriptLocal"/ssh/opsauto
fi

#Wrapper function to launch arbitrary commands within the ubiquitous_bash environment, including its PATH with scriptBin.
_bin() {
	"$@"
}

#Launch internal functions as commands, and other commands, as root.
_sudo() {
	sudo -n "$scriptAbsoluteLocation" _bin "$@"
}

_true() {
	true
}
_false() {
	false
}
_echo() {
	echo "$@"
}

#Stop if script is imported, parameter not specified, and command not given.
if [[ "$ub_import" == "true" ]] && [[ "$ub_import_param" == "" ]] && [[ "$1" != '_'* ]]
then
	_messagePlain_warn 'import: missing: parameter, missing: command' | _user_log-ub
	ub_import=""
	return 1 > /dev/null 2>&1
	exit 1
fi

#Set "ubOnlyMain" in "ops" overrides as necessary.
if [[ "$ubOnlyMain" != "true" ]]
then
	
	#Launch command named by link name.
	if scriptLinkCommand=$(_getScriptLinkName)
	then
		if [[ "$scriptLinkCommand" == '_'* ]]
		then
			"$scriptLinkCommand" "$@"
			internalFunctionExitStatus="$?"
			
			#Exit if not imported into existing shell, or bypass requested, else fall through to subsequent return.
			if [[ "$ub_import" != "true" ]] || [[ "$ub_import_param" == "--bypass" ]]
			then
				#export noEmergency=true
				exit "$internalFunctionExitStatus"
			fi
			ub_import=""
			return "$internalFunctionExitStatus" > /dev/null 2>&1
			exit "$internalFunctionExitStatus"
		fi
	fi
	
	# NOTICE Launch internal functions as commands.
	#if [[ "$1" != "" ]] && [[ "$1" != "-"* ]] && [[ ! -e "$1" ]]
	#if [[ "$1" == '_'* ]] || [[ "$1" == "true" ]] || [[ "$1" == "false" ]]
	if [[ "$1" == '_'* ]]
	then
		"$@"
		internalFunctionExitStatus="$?"
		
		#Exit if not imported into existing shell, or bypass requested, else fall through to subsequent return.
		if [[ "$ub_import" != "true" ]] || [[ "$ub_import_param" == "--bypass" ]]
		then
			#export noEmergency=true
			exit "$internalFunctionExitStatus"
		fi
		ub_import=""
		return "$internalFunctionExitStatus" > /dev/null 2>&1
		exit "$internalFunctionExitStatus"
		#_stop "$?"
	fi
fi

[[ "$ubOnlyMain" == "true" ]] && export ubOnlyMain="false"

#Do not continue script execution through program code if critical global variables are not sane.
[[ ! -e "$scriptAbsoluteLocation" ]] && exit 1
[[ ! -e "$scriptAbsoluteFolder" ]] && exit 1
_failExec || exit 1

#Return if script is under import mode, and bypass is not requested.
if [[ "$ub_import" == "true" ]] && [[ "$ub_import_param" != "--bypass" ]]
then
	return 0 > /dev/null 2>&1
	exit 0
fi

#####Entry

#"$scriptAbsoluteLocation" _setup


_main "$@"


