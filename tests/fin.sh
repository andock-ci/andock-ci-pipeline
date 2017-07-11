#!/usr/bin/env bash

FIN_VERSION=1.6.0

# Console colors
red='\033[0;91m'
red_bg='\033[101m'
green='\033[0;32m'
green_bg='\033[42m'
yellow='\033[1;33m'
NC='\033[0m'

#-------------------------------- OS Checks ------------------------------------
is_linux ()
{
	uname | grep 'Linux' >/dev/null
}

is_ubuntu ()
{
	if [ -r /etc/lsb-release ]; then
		lsb_dist="$(. /etc/lsb-release && echo "$DISTRIB_ID")"
		lsb_release="$(. /etc/lsb-release && echo "$DISTRIB_RELEASE")"
	fi

	if [[ "$lsb_dist" != 'Ubuntu' || $(ver_to_int "$lsb_release") < $(ver_to_int '14.04') ]]; then
		return 1
	fi

	return 0
}

is_windows ()
{
	uname | grep 'CYGWIN_NT' >/dev/null
}

is_mac ()
{
	uname | grep 'Darwin' >/dev/null
}
#------------------------------------------------------------------------------


#---------------------------- Global Constants --------------------------------

DOCKSAL_VERSION="${DOCKSAL_VERSION:-master}"

REQUIREMENTS_DOCKER='17.04.0-ce'
REQUIREMENTS_DOCKER_COMPOSE='1.12.0'
REQUIREMENTS_DOCKER_MACHINE='0.10.0'
REQUIREMENTS_VBOX='5.1.18'
REQUIREMENTS_WINPTY='0.4.2'
REQUIREMENTS_WINPTY_CYGWIN='2.6.1'

URL_VBOX_MAC="http://download.virtualbox.org/virtualbox/5.1.18/VirtualBox-5.1.18-114002-OSX.dmg"
URL_VBOX_WIN="http://download.virtualbox.org/virtualbox/5.1.18/VirtualBox-5.1.18-114002-Win.exe"

# Self Paths
FIN_PATH="/usr/local/bin/fin"
FIN_PATH_UPDATED="/usr/local/bin/fin.updated"
FIN_AUTOCOMPLETE_PATH="/usr/local/bin/fin-bash-autocomplete"
# Configuration paths
# Rewrite $HOME on windows to be absolute path in Unix notation
if is_windows; then
	BABUN_WIN_HOME="$HOME"
	# Cannot use cygpath_abs_unix here as it's being defined much later
	HOME="/$(cygpath -m $HOME | sed 's/^\/cygdrive//' | sed 's/\([A-Z]\)\:/\l\1/')"
fi
# DO NOT REMOVE HOST_HOME. It is used in some stack yml files and is necessary on Windows.
export HOST_HOME="$HOME"
OLD_CONFIG_DIR="$HOME/.drude"
CONFIG_DIR="$HOME/.docksal"
CONFIG_ENV="$CONFIG_DIR/docksal.env"
CONFIG_ALIASES="$CONFIG_DIR/alias"
CONFIG_LAST_CHECK="$CONFIG_DIR/.last_check"
CONFIG_LAST_PING="$CONFIG_DIR/.last_ping"
CONFIG_MACHINES="$CONFIG_DIR/machines"
CONFIG_MACHINES_ENV="$CONFIG_DIR/machines/.env"
CONFIG_MACHINE_ACTIVE="$CONFIG_MACHINES/.active"
mkdir -p "$CONFIG_PROJECTS" >/dev/null 2>&1
# BIN folder
CONFIG_BIN_DIR="$CONFIG_DIR/bin"
CONFIG_DOWNLOADS_DIR="$CONFIG_BIN_DIR/downloads"
DOCKER_BIN="$CONFIG_BIN_DIR/docker"
DOCKER_COMPOSE_BIN="$CONFIG_BIN_DIR/docker-compose"
DOCKER_COMPOSE_BIN_NIX="/usr/local/bin/docker-compose"
DOCKER_MACHINE_BIN="$CONFIG_BIN_DIR/docker-machine"
DOCKER_MACHINE_BIN_NIX="/usr/local/bin/docker-machine"
WINPTY_BIN="$CONFIG_BIN_DIR/winpty"
vboxmanage="VBoxManage"
is_windows && vboxmanage="/cygdrive/c/Program Files/Oracle/VirtualBox/VBoxManage.exe"
# Stacks folder
CONFIG_STACKS_DIR="$HOME/.docksal/stacks"
mkdir -p "$CONFIG_STACKS_DIR" >/dev/null 2>&1

# Where custom commands live (relative path)
DOCKSAL_COMMANDS_PATH=".docksal/commands"

# Network settings
DOCKSAL_HOST_IP_BOOT2DOCKER="192.168.64.1"
DOCKSAL_HOST_IP_NATIVE="192.168.65.1"
DOCKSAL_DEFAULT_IP="192.168.64.100"
DOCKSAL_DEFAULT_SUBNET="192.168.64.1/24"
DOCKSAL_DEFAULT_DNS="10.0.2.3"
DOCKSAL_DEFAULT_DNS_NIX="8.8.8.8"
DOCKSAL_DNS_DOMAIN="${DOCKSAL_DNS_DOMAIN:-docksal}"
DOCKSAL_VHOST_PROXY_PORT_HTTP="${DOCKSAL_VHOST_PROXY_PORT_HTTP:-80}"
DOCKSAL_VHOST_PROXY_PORT_HTTPS="${DOCKSAL_VHOST_PROXY_PORT_HTTPS:-443}"

DEFAULT_MACHINE_NAME='docksal'
DEFAULT_MACHINE_PROVIDER='virtualbox'
DEFAULT_MACHINE_VBOX_RAM='1024' #mb
DEFAULT_MACHINE_VBOX_HDD='50000' #mb
DEFAULT_MACHINE_DO_SIZE='1gb' # digitalocean default size (512mb, 1gb, 2gb...)

# Stats
# fin sends a minimal ping with OS and fin version number
DOCKSAL_STATS_TID='UA-93724315-1'
DOCKSAL_STATS_URL='http://www.google-analytics.com/collect'
DOCKSAL_STATS_OPTOUT=${DOCKSAL_STATS_OPTOUT:-0}

#---------------------------- URL references --------------------------------
URL_REPO="https://raw.githubusercontent.com/docksal/docksal"
URL_REPO_UI="https://github.com/docksal/docksal"
URL_REPO_DRUPAL7="https://github.com/docksal/drupal7.git"
URL_REPO_DRUPAL8="https://github.com/docksal/drupal8.git"
URL_REPO_WORDPRESS="https://github.com/docksal/wordpress.git"
URL_REPO_MAGENTO="https://github.com/docksal/magento.git"
URL_FIN="${URL_REPO}/${DOCKSAL_VERSION}/bin/fin"
URL_STACKS_SERVICES="${URL_REPO}/${DOCKSAL_VERSION}/stacks/services.yml"
URL_STACKS_STACK_ACQUIA="${URL_REPO}/${DOCKSAL_VERSION}/stacks/stack-acquia.yml"
URL_STACKS_STACK_ACQUIA_STATIC="${URL_REPO}/${DOCKSAL_VERSION}/stacks/stack-acquia-static.yml"
URL_STACKS_STACK_DEFAULT="${URL_REPO}/${DOCKSAL_VERSION}/stacks/stack-default.yml"
URL_STACKS_STACK_DEFAULT_STATIC="${URL_REPO}/${DOCKSAL_VERSION}/stacks/stack-default-static.yml"
URL_STACKS_VOLUMES_BIND="${URL_REPO}/${DOCKSAL_VERSION}/stacks/volumes-bind.yml"
URL_STACKS_VOLUMES_NFS="${URL_REPO}/${DOCKSAL_VERSION}/stacks/volumes-nfs.yml"
URL_STACKS_VOLUMES_UNISON="${URL_REPO}/${DOCKSAL_VERSION}/stacks/volumes-unison.yml"

URL_DOCKER_MAC="https://get.docker.com/builds/Darwin/x86_64/docker-${REQUIREMENTS_DOCKER}.tgz"
URL_DOCKER_NIX="https://get.docker.com/"
URL_DOCKER_WIN="https://get.docker.com/builds/Windows/x86_64/docker-${REQUIREMENTS_DOCKER}.zip"
URL_DOCKER_COMPOSE_MAC="https://github.com/docker/compose/releases/download/${REQUIREMENTS_DOCKER_COMPOSE}/docker-compose-Darwin-x86_64"
URL_DOCKER_COMPOSE_NIX="https://github.com/docker/compose/releases/download/${REQUIREMENTS_DOCKER_COMPOSE}/docker-compose-Linux-x86_64"
URL_DOCKER_COMPOSE_WIN="https://github.com/docker/compose/releases/download/${REQUIREMENTS_DOCKER_COMPOSE}/docker-compose-Windows-x86_64.exe"
URL_DOCKER_MACHINE_MAC="https://github.com/docker/machine/releases/download/v${REQUIREMENTS_DOCKER_MACHINE}/docker-machine-Darwin-x86_64"
URL_DOCKER_MACHINE_NIX="https://github.com/docker/machine/releases/download/v${REQUIREMENTS_DOCKER_MACHINE}/docker-machine-Linux-x86_64"
URL_DOCKER_MACHINE_WIN="https://github.com/docker/machine/releases/download/v${REQUIREMENTS_DOCKER_MACHINE}/docker-machine-Windows-x86_64.exe"
URL_BOOT2DOCKER="https://github.com/boot2docker/boot2docker/releases/download/v${REQUIREMENTS_DOCKER}/boot2docker.iso"

URL_WINPTY="https://github.com/rprichard/winpty/releases/download/${REQUIREMENTS_WINPTY}/winpty-${REQUIREMENTS_WINPTY}-cygwin-${REQUIREMENTS_WINPTY_CYGWIN}-ia32.tar.gz"

IMAGE_SSH_AGENT=${IMAGE_SSH_AGENT:-docksal/ssh-agent:1.0}
IMAGE_VHOST_PROXY=${IMAGE_VHOST_PROXY:-docksal/vhost-proxy:1.0}
IMAGE_DNS=${IMAGE_DNS:-docksal/dns:1.0}

#---------------------------- Helper functions --------------------------------

DOCKSAL_PATH='' #docksal path value will be cached here

echo-red () { echo -e "${red}$1${NC}"; }
echo-green () { echo -e "${green}$1${NC}"; }
echo-green-bg () { echo -e "${green_bg}$1${NC}"; }
echo-yellow () { echo -e "${yellow}$1${NC}"; }
echo-error () {
	echo -e "${red_bg} ERROR: ${NC} ${red}$1${NC}";
	local unused="$2$3" # avoid IDE warning
	shift
	# Echo other parameters indented. Can be used for error description or suggestions.
	while [[ "$1" != "" ]]; do
		echo -e "         $1";
		shift
	done
}
# rewrite previous line
echo-rewrite ()
{
	echo -en "\033[1A"
	echo -e "\033[0K\r""$1"
}
echo-rewrite-ok ()
{
	echo-rewrite "$1 ${green}[OK]${NC}"
}

# Exits fin if previous command exited with non-zero code
if_failed ()
{
	if [ ! $? -eq 0 ]; then
		echo-red "$*"
		exit 1
	fi
}
# Like if_failed but with more strict error
if_failed_error ()
{
	if [ ! $? -eq 0 ]; then
		echo-error "$@"
		exit 1
	fi
}

_PWD=$(which pwd)
# Override default pwd function on windows and remove /cygdrive part from the path
pwd ()
{
	# -L option should be used at all times because running pwd via absolute path /bin/pwd
	# on Linux and Windows forces it to resolve current logical dir to physical dir
	# (resolves symlink into target dir). -L forces using logical dir just like running pwd alone
	if is_windows; then
		"$_PWD" "-L" | sed 's/^\/cygdrive//'
	else
		"$_PWD" "-L"
	fi
}

# Returns absolute path to a file/folder in a Unix notation under cygwin on Windows.
# cygpath -m returns something like C:/Users/user/...
# This function converts that into something like /c/Users/user/...
# @param $1 file/folder
cygpath_abs_unix ()
{
	echo "/$(cygpath -m $1 | sed 's/^\/cygdrive//' | sed 's/\([A-Z]\)\:/\l\1/')"
}

# Search for a file/directory in a directory tree upwards. Return its path.
# @param $1 filename
upfind ()
{
	if [[ $1 == '' ]]; then return 1; fi
	local _path
	_path=$( #incapsulate cd
		while [[ ! -f $1 ]] && [[ ! -d $1 ]] && [[ $PWD != / ]]; do
			cd ".."
		done;
		if [[ -f $1 ]] || [[ -d $1 ]]; then echo $PWD; exit; fi
	)
	# On Windows compensate for getting down to "" and return full absolute path in Unix notation
	# upfind on windows may return FAKED HOME PATH! because of that. KEEP that in mind
	[[ "$_path" == "" ]] && _path="$HOME"
	if is_windows; then
		echo "$(cygpath_abs_unix ${_path})"
	else
		echo "$_path"
	fi
}

# Get path to .docksal folder using upfind
get_project_path ()
{
	if [ -z "$DOCKSAL_PATH" ]; then
		DOCKSAL_PATH=$(upfind ".docksal")
	fi
	# If we reached $HOME, then we did not find the project root.
	if [[ "$DOCKSAL_PATH" != "$HOME" ]]; then
		echo "$DOCKSAL_PATH"
	fi
}

# Get path to project folder
# Outputs a Windows compatible path on Windows, e.g. "c:/path/subpath", not "/c/path/subpath".
get_project_path_dc ()
{
	if is_windows ; then
		local _path="$(get_project_path)"
		[[ "$_path" != "" ]] && cygpath -m "$_path"
	else
		echo "$(get_project_path)"
	fi
}

# Get path to global .docksal folder (~/.docksal directory).
# Outputs a Windows compatible path on Windows, e.g. "c:/path/subpath", not "/c/path/subpath".
get_config_dir_dc ()
{
	if is_windows ; then
		cygpath -m "$CONFIG_DIR"
	else
		echo "$CONFIG_DIR"
	fi
}

# Returns absolute path
# @param $1 file/dir relative path
get_abs_path ()
{
	local _dir
	if [[ -f "$1" ]]; then
		_dir="$(dirname $1)"
	elif [[ -d "$1" ]]; then
		_dir="$1"
	else
		echo "Path \"$1\" does not exist"
		return 1
	fi
	echo "$(cd "${_dir}" ; pwd)"
}

# Return current path relative to project root with trailing slash
get_current_relative_path ()
{
	# Check that we're inside project folder
	local proj_root=$(get_project_path)
	local cwd=$(pwd)
	# On Windows pwd may return a cygwin absolute path.
	# We need a full absolute path here (/c/Users/user/... instead of /home/user), thus the special handling.
	is_windows && cwd=$(cygpath_abs_unix $(pwd))

	# Output relative path unless we are in the project root (empty relative path)
	if [[ "$proj_root" != "$cwd" ]]; then
		# if cwd substract proj_root is still cwd then it means we're out of proj_root (unsubstractable)
		# ex: cwd=/a/b/c/d, proj_root=/a/b/c, pathdiff==d
		# ex: cwd=/a/b, proj_root=/a/b/c, pathdiff==/a/b
		local pathdiff=${cwd#${proj_root}/}
		echo "$pathdiff"
	fi
}

# Get mysql connection string
get_mysql_connect ()
{
	# Run drush forcing tty to false to avoid colored output string from drush.
	cleaned_string=$(echo $(_exec drush sql-connect) | sed -e 's/[^a-zA-Z0-9_-]$//')
	echo "$cleaned_string"
}

# Get container id by service name
# @param $1 docker compose service name (e.g. cli)
# @return docker container id
get_container_id ()
{
	# Trim any control characters from the output, otherwise there will be issues passing it to the docker binary on Windows.
	echo $(docker-compose ps -q $1 2>/dev/null | tr -d '[:cntrl:]')
}

# Run command on Windows with elevated privileges
winsudo ()
{
	cygstart --action=runas cmd /c "$@"
}

# Universal Bash parameter parsing
# Parse equals separated params into named local variables
# Standalone named parameter value will equal param name (--force creates variable $force=="force")
# Parses multi-valued named params into array (--path=path1 --path=path2 creates ${path[*]} array)
# Parses un-named params into ${ARGV[*]} array
# @author Oleksii Chekulaiev
# @version v1.1 (Jul-14-2016)
parse_params ()
{
	local existing_named
	local ARGV=()
	echo "local ARGV=(); "
	while [[ "$1" != "" ]]; do
		# If equals delimited named parameter
		if [[ "$1" =~ ^..*=..* ]]; then
			# key is part before first =
			local _key=$(echo "$1" | cut -d = -f 1)
			# val is everything after key and = (protect from param==value error)
			local _val="${1/$_key=}"
			# remove dashes from key name
			_key=${_key//\-}
			# search for existing parameter name
			if (echo "$existing_named" | grep "\b$_key\b" >/dev/null); then
				# if name already exists then it's a multi-value named parameter
				# re-declare it as an array if needed
				if ! (declare -p _key 2> /dev/null | grep -q 'declare \-a'); then
					echo "$_key=(\"\$$_key\");"
				fi
				# append new value
				echo "$_key+=('$_val');"
			else
				# single-value named parameter
				echo "local $_key=\"$_val\";"
				existing_named=" $_key"
			fi
		# If standalone named parameter
		elif [[ "$1" =~ ^\-. ]]; then
			# remove dashes
			local _key=${1//\-}
			echo "local $_key=\"$_key\";"
		# non-named parameter
		else
			echo "ARGV+=('$1');"
		fi
		shift
	done
}

#------------------------- Basics check functions -----------------------------

is_docker_native ()
{
	# comparison returns error codes
	[[ "$DOCKER_NATIVE" == "1" ]]
}

# Check if file has crlf endings
# param $1 filename
is_crlf ()
{
	[[ "$(grep -c $'\r' $1)" -gt 0 ]]
}

# Check if file has crlf endings and fix it
# param $1 filename
fix_crlf ()
{
	CR=$'\r'
	cat "$1" | sed "s/$CR//" | tee "$1" >/dev/null
}

# Check if file has crlf endings, warn about it and fix it
# param $1 filename
fix_crlf_warning ()
{

	if (is_crlf "$1"); then
		if is_tty; then
			echo -e "${red}WARNING: ${NC}${yellow}$1${NC} has CRLF line endings."
			echo-red "You should configure your git or repo to always use LF line endings for Docksal files"
			_confirm "Fix this file automatically?"
		fi
		fix_crlf "$1"
	fi
}

# checks if binary exists and fails is it isn't
check_binary_found ()
{
	if ( which "$1" 2>/dev/null >/dev/null ); then
		return 0
	else
		echo-red "$1 executable was not found. (Try running 'fin update')"
		exit 1
	fi
}

check_winpty_found ()
{
	! is_windows && return
	# Do not set winpty in non-zsh environment e.g. bash shell which Docksal creates a link for on desktop
	if [[ "$ZSH" != "" ]]; then
		check_binary_found 'winpty'
		# -Xallow-non-tty: allow stdin/stdout to not be ttys
		# This is an undocumented feature of winpty which makes thing work much better on Windows,
		# including pipes (|), stream redirects (< >) and variable substitution from a sub-shell ( $() )
		# https://github.com/rprichard/winpty/commit/222ecb9f4404cce3cdbafa0a97c7c3da4ce2b3c2
		# I wish it was documented... Could have saved many hours of pain making things work on Windows.
		winpty='winpty -Xallow-non-tty'
	fi
}

is_docker_running ()
{
	if ! is_linux && ! is_docker_native; then
		if ! is_docker_machine_running; then return 255; fi
	fi
	# Check if docker is running via docker info.
	# This operation is instant even if docker is not running (assuming a socket is used).
	which docker >/dev/null 2>&1 && docker info >/dev/null || return 1
}

# Check whether we have a working c.
# Otherwise we are running in a non-tty environment ( e.g. Babun on Windows).
# We assume the environment is interactive if there is a tty.
# All other direct checks don't work well in and every environment and scripts.
is_tty ()
{

	[[ "$(/usr/bin/tty || true)" != "not a tty" ]]

	# TODO: rewrite this check using [ -t ] test
	# http://stackoverflow.com/questions/911168/how-to-detect-if-my-shell-script-is-running-through-a-pipe/911213#911213
	# 0: stdin, 1: stdout, 2: stderr
	# [ -t 0 -a -t 1 ]
}

#---------------------------- Other helper functions -------------------------------

testing_warn ()
{
	[[ "$DOCKSAL_VERSION" != 'master' ]] && is_tty && \
		echo-yellow "[!] Using Docksal version: ${DOCKSAL_VERSION}"
}

# Convert version string like 1.2.3 to integer for comparison
# param $1 version string of 3 components max (e.g. 1.10.3)
ver_to_int ()
{
	printf "%03d%03d%03d" $(echo "$1" | tr -d '[:alpha:]' | tr -d '-' | tr '.' ' ')
}

#---------------------------- Control functions -------------------------------

check_docksal_environment ()
{
	check_docksal && check_docker_running
}

check_docker_running ()
{
	[[ "$UPGRADE_IN_PROGRESS" == "1" ]] && return 0
	# Check cached value
	[[ "$DOCKER_RUNNING" == "true" ]] && return 0
	local docker_status

	check_binary_found 'docker'
	check_binary_found 'docker-compose'
	if ! is_docker_native && ! is_docker_version; then
		echo-error "Required Docker version is $REQUIREMENTS_DOCKER"
		echo -e "Run ${yellow}fin update${NC} to update"
		exit 1
	fi
	if is_docker_native && ! is_docker_version; then
		echo-yellow "Your Docker version is out of date. Please update to $REQUIREMENTS_DOCKER"
	fi

	is_docker_running
	docker_status=$?

	if [[ ${docker_status} -eq 255 ]] && ! is_docker_native; then
		echo-yellow "It looks like '$DOCKER_MACHINE_NAME' docker machine is not running."
		_confirm "Run 'fin vm start' to start it now?"
		docker_machine_start
		if_failed "Could not start Docksal docker machine properly"
		# re-check status
		eval $(docker-machine env --shell=bash "$DOCKER_MACHINE_NAME")
		docker info >/dev/null
		docker_status=$?
	fi

	if [[ ${docker_status} -eq 0 ]]; then
		DOCKER_RUNNING="true"
	else
		if is_docker_native; then
			exit 1
		elif is_linux; then
			# Remind the used about running 'newgrp docker' after install.
			if ! (id -nG | grep docker >/dev/null 2>&1) && [[ "$(id -u)" != "0" ]] ; then
				echo-error "Current user is not part of the docker group." \
					"Have you run ${yellow}newgrp docker${NC} after ${yellow}fin update${NC}?"
				exit 1
			fi
			# Check if docker daemon is running and offer to start it if not.
			if ! (ps aux | grep dockerd | grep -v grep); then
				_confirm "Start docker daemon now ('service docker start')?"
				sudo service docker start
			fi
		else
			echo-error "Looks like your Docker client and Docker server are incompatible." \
				"${green}Run ${NC}${yellow}fin update${NC}${green} to update.${NC}"
			exit 1
		fi
	fi
}

is_vbox_version ()
{
	! which "$vboxmanage" >/dev/null 2>&1 && return 1

	local virtualbox_version=$("$vboxmanage" -v | sed "s/r.*//" 2>/dev/null)
	[[ $(ver_to_int "$virtualbox_version") < $(ver_to_int "$REQUIREMENTS_VBOX") ]] && \
		return 2

	return 0
}

is_docker_version ()
{
	! which docker >/dev/null 2>&1 && return 1

	local version=$(docker -v | sed "s/.*version \(.*\),.*/\1/")

	[[ $(ver_to_int "$REQUIREMENTS_DOCKER") -gt $(ver_to_int "$version") ]] && \
		return 1;

	return 0;
}

is_docker_server_version ()
{
	! which docker >/dev/null 2>&1 && return 1

	local version=$(docker version --format '{{.Server.Version}}' 2>/dev/null)

	[[ $(ver_to_int "$REQUIREMENTS_DOCKER") -gt $(ver_to_int "$version") ]] && \
		return 1;

	return 0;
}

is_docker_compose_version ()
{
	! which docker-compose >/dev/null 2>&1 && return 1

	# Trim any control characters from docker-compose output (necessary on Windows)
	local version=$(docker-compose version --short | tr -d '[:cntrl:]')
	[[ $(ver_to_int "$REQUIREMENTS_DOCKER_COMPOSE") > $(ver_to_int "$version") ]] && \
		return 1;

	return 0;
}

is_docker_machine_version ()
{
	! which docker-machine >/dev/null 2>&1 && return 1

	local version=$(docker-machine -v | sed "s/.*version \(.*\),.*/\1/")
	[[ $(ver_to_int "$REQUIREMENTS_DOCKER_MACHINE") > $(ver_to_int "$version") ]] && \
		return 1;

	return 0;
}

is_winpty_version ()
{
	! which "$WINPTY_BIN" >/dev/null 2>&1 && return 2

	local version=$("$WINPTY_BIN" --version | head -1 | sed "s/.*version \(.*\).*/\1/")
	[[ $(ver_to_int "$REQUIREMENTS_WINPTY") > $(ver_to_int "$version") ]] && \
		return 1;

	return 0;
}

check_vbox_version ()
{
	# Provide ability to skip checking for vbox version
	[[ "$SKIP_VBOX_VERSION_CHECK" == "1" ]] && return;

	is_vbox_version
	local res=$?
	[[ "$res" == "1" ]] && echo-red "$vboxmanage binary was not found" && update_virtualbox
	[[ "$res" == "2" ]] && echo-red "VirtualBox version should be $REQUIREMENTS_VBOX or higher" && update_virtualbox
}

# Check that .docksal is present
check_docksal ()
{
	if [[ "$(get_project_path)" == "" ]] ; then
		echo-error "Cannot detect project root." \
			"Please make sure you have ${yellow}.docksal${NC} directory in the root of your project." \
			"To setup a basic Docksal stack in the current directory run ${yellow}fin config generate${NC}"
		exit 1
	fi
}

# Project uniqueness checks
check_project_unique ()
{
	# Format: project:project-root:virtual-host
	local _projects=$(docker ps --all \
				--filter 'label=com.docker.compose.service=web' \
				--format '{{.Label "com.docker.compose.project"}}:{{.Label "io.docksal.project-root"}}:{{.Label "io.docksal.virtual-host"}}')

	for _project in $_projects; do
		IFS=':' read _project_name _project_root _project_vhost <<< "$_project"

		# Prevent duplicate project names
		if [[ "$_project_name" == "$COMPOSE_PROJECT_NAME_SAFE" ]] && [[ "$_project_root" != "$PROJECT_ROOT" ]]; then
			echo-error "Another project is already using the name '${COMPOSE_PROJECT_NAME_SAFE}'" \
				"Change the name of the current project by renaming the project folder (folder name defines the project name and has to be unique)" \
				"or remove the other project's stack by running ${yellow}fin rm${NC} in ${yellow}$_project_root${NC}"
			exit 1
		fi

		# Prevent duplicate vhost names
		# TODO: handle non-default VIRTUAL_HOST definitions
		if [[ "$_project_vhost" =~ ^$VIRTUAL_HOST ]] && [[ "$_project_root" != "$PROJECT_ROOT" ]]; then
			echo-error "Another project is already using the virtual hostname '${VIRTUAL_HOST}'" \
				"Use a different hostname for this project by overriding the VIRTUAL_HOST variable in docksal.env" \
				"or remove the other project's stack by running ${yellow}fin rm${NC} in ${yellow}$_project_root${NC}"
			exit 1
		fi
	done
}

# Yes/no confirmation dialog with an optional message
# @param $1 confirmation message
_confirm ()
{
	# Skip checks if not running interactively (not a tty or not on Windows)
	if ! is_tty; then return 0; fi

	while true; do
		read -p "$1 [y/n]: " answer
		case "$answer" in
			[Yy]|[Yy][Ee][Ss] )
				break
				;;
			[Nn]|[Nn][Oo] )
				exit 1
				;;
			* )
				echo 'Please answer yes or no.'
		esac
	done
}

#-------------------------- Containers management -----------------------------

_start_containers ()
{
	check_docker_running
	echo-green "Starting services..."
	docker-compose up -d --remove-orphans && \
		# Give time for startup.sh in CLI to execute otherwise UID is changed too quickly
		# which prevents xdebug from loading properly
		sleep 1 && \
		# TODO: remove in September 2017, as this functionality was ported inside docksal/cli
		_set_cli_uid && \
		_vhost_proxy_connect
}

# @param $1 "-a" || "--all"
_stop_containers ()
{
	if [[ $1 == '-a' ]] || [[ $1 == '--all' ]]; then
		check_docker_running
		echo-green "Stopping all running services from all projects..."
		# stop all but system containers (--label "io.docksal.group=system")
		docker ps --format '{{.Names}} {{.Label "io.docksal.group"}}' | grep -v 'system' | xargs docker stop
		return
	fi

	if [[ "$1" == "proxy" ]] ; then
		echo-green 'Stopping Docksal HTTP/HTTPS reverse proxy service...'
		docker stop docksal-vhost-proxy >/dev/null
		return
	fi

	if [[ "$1" == "dns" ]] ; then
		echo-green 'Stopping Docksal DNS service...'
		docker stop docksal-dns >/dev/null
		return
	fi

	if [[ "$1" == "ssh-agent" ]] ; then
		echo-green 'Stopping Docksal ssh-agent service...'
		docker stop docksal-ssh-agent >/dev/null
		return
	fi

	check_docksal_environment
	echo-green "Stopping services..."
	docker-compose stop
}

_restart_containers ()
{
	_stop_containers && _start_containers
}

# @param $1 container_name
_remove_containers ()
{
	check_docksal_environment
	if [[ $1 == "" ]]; then
		echo-yellow "Removing containers..."

		# Disconnect proxy from the project network, otherwise network will not be removed.
		# Figure out the default project network name
		local network="${COMPOSE_PROJECT_NAME_SAFE}_default"
		docker network disconnect "$network" docksal-vhost-proxy >/dev/null 2>&1

		# Taking the whole docker-compose project down (this removes containers, volumes and networks)
		docker-compose down --volumes --remove-orphans
	else
		# Removing requested containers only
		docker-compose kill "$@" && docker-compose rm -vf "$@"
	fi
}

# Remove containers for non-exiting projects.
_remove_dangling_containers ()
{
	echo-green "Checking for orphaned containers..."
	local projects=$(docker ps --all \
		--filter 'label=io.docksal.project-root' \
		--filter 'label=com.docker.compose.project' \
		--format '{{ .Label "com.docker.compose.project" }}:{{ .Label "io.docksal.project-root" }}')
	for project in $projects; do
		IFS=':' read project_name project_root <<< "$project"
		if [[ ! -d "$project_root" ]]; then
			echo "Directory for project \"$project_name\" does not exist. Removing containers..."
			docker ps -q -a --filter "label=com.docker.compose.project=${project_name}" | xargs docker rm -fv
			local network="${project_name}_default"
			docker network disconnect "$network" docksal-vhost-proxy
			docker network rm "$network"
		fi
	done
}

# Remove dangling images
_remove_dangling_images ()
{
	echo-green "Removing dangling images..."
	docker images -qf dangling=true | xargs docker rmi 2>/dev/null
}

# Remove dangling images
_remove_dangling_volumes ()
{
	echo-green "Removing dangling volumes..."
	docker volume ls -qf dangling=true | xargs docker volume rm 2>/dev/null
}

# Cleanup unused images and containters
# @param $1 --hard if set removes all stopped containers
cleanup ()
{
	check_docker_running
	if [[ "$1" == "--hard" ]] && [[ "$(docker ps -aqf status=exited)" != "" ]]; then
		echo -e "${red}WARNING: ${yellow}Preparing to delete all currently stopped containers:${NC}"
		docker ps -af status=exited --format "{{.Label \"com.docker.compose.project\"}}_{{.Label \"com.docker.compose.service\"}}\t\t{{.Status}} ({{.Image}})"
		printf '–%.0s' $(seq 1 40)
		echo -e "${yellow}"
		_confirm "Continue?"
		echo -e "${NC}"
		#--
		echo-green "Removing stopped containers..."
		docker ps -aqf status=exited | xargs docker rm -vf
	fi

	_remove_dangling_containers
	_remove_dangling_images
	_remove_dangling_volumes

	# TODO: remove below lines in September 2017
	rm -f "$OLD_CONFIG_DIR/Vagrantfile."* >/dev/null 2>&1
	rm -f "$OLD_CONFIG_DIR/backups/Vagrantfile."* >/dev/null 2>&1
	rm -r "$OLD_CONFIG_DIR/backups" >/dev/null 2>&1
	rm -f "$OLD_CONFIG_DIR/vagrant.yml."* >/dev/null 2>&1
	rm -f "$OLD_CONFIG_DIR/backups/vagrant.yml."* >/dev/null 2>&1
	rm -f "$OLD_CONFIG_DIR/b2d_version" >/dev/null 2>&1

	# TODO: remove in September 2017
	rm -f "$CONFIG_DIR/last_check" >/dev/null 2>&1
}

# Connect vhost-proxy to all bridge networks on the host
_vhost_proxy_connect ()
{
	# Figure out the default project network name
	local network="${COMPOSE_PROJECT_NAME_SAFE}_default"
	docker network connect "$network" docksal-vhost-proxy >/dev/null 2>&1
	if [[ $? == 0 ]]; then
		echo-green "Connected vhost-proxy to \"${network}\" network."
		# Run a dummy container to trigger docker-gen to refresh proxy configuration.
		docker run --rm --entrypoint=echo ${IMAGE_VHOST_PROXY} >/dev/null 2>&1
	fi
}

#------------------------------ Help functions --------------------------------

# Nicely prints command help
# @param $1 command name
# @param $2 description
# @param $3 [optional] command color
printh ()
{
	local COMMAND_COLUMN_WIDTH=25;
	case "$3" in
		yellow)
			printf "  ${yellow}%-${COMMAND_COLUMN_WIDTH}s${NC}" "$1"
			echo -e "	$2"
			;;
		green)
			printf "  ${green}%-${COMMAND_COLUMN_WIDTH}s${NC}" "$1"
			echo -e "	$2"
			;;
		*)
			printf "  %-${COMMAND_COLUMN_WIDTH}s" "$1"
			echo -e "	$2"
			;;
	esac

}

# Show help for fin or for certain command
# $1 name of command to show help for
show_help ()
{
	local project_commands_path="$(get_project_path)/$DOCKSAL_COMMANDS_PATH"
	local global_commands_path="$HOME/$DOCKSAL_COMMANDS_PATH"
	local custom_commands_list

	# If nonempty param then show help for a certain command
	if [[ ! -z "$1" ]]; then
		# Check for help function for specific command
		type "show_help_$1" >/dev/null 2>&1
		if [ $? -eq 0 ]; then
			show_help_$1
			exit
		fi
		# Check for custom command file
		# Try global command
		local _command="$global_commands_path/$1"
		# But if local command exists then override
		[ -f "$project_commands_path/$1" ] && _command="$project_commands_path/$1"
		#
		if [ -f "$_command" ]; then
			echo -en "${green}fin $1${NC} - "
			local _help_contents=$(cat "$_command" | grep '^##' | sed "s/^##[ ]*//g")
			echo -e "$_help_contents"
			echo
			exit
		fi
	fi

	printh "Docksal Fin v$FIN_VERSION command reference" "" "green"

	echo
	if is_linux; then
		printh "start (up)" "Start project services"
	else
		printh "start (up)" "Start project services"
	fi
	printh "stop [-a (--all)]" "Stop project services (-a stops all services on all projects)"
	printh "restart" "Restart project services"
	printh "reset" "Recreate project services and containers (${yellow}fin help reset${NC})"
	printh "remove (rm)" "Stop project services and remove their containers (${yellow}fin help remove${NC})"
	printh "status (ps)" "List project services"

	echo
	if ! is_linux && ! is_docker_native; then
		printh "vm <command>" "Docksal's Virtualbox machine commands (${yellow}fin help vm${NC})" "yellow"
		printh "  start, stop, restart, status, ls, ssh, remove, ip, env, ram, stats"
	fi

	echo
	printh "bash [service]" "Open shell into service's container. Defaults to ${yellow}cli${NC}"
	printh "exec <command|file>" "Execute a command or a file in ${yellow}cli${NC}"
	printh "exec-url <url>" "Download script from URL and run it on host (URL should be public)"
	printh "logs [service]" "Show Docker logs for service container (e.g. Apache logs)"

	echo
	printh "drush [command]" "Execute Drush command (Drupal)"
	printh "drupal [command]" "Execute Drupal Console command (Drupal 8)"
	printh "wp [command]" "Execute WP-CLI command (WordPress)"

	echo
	printh "sqlc" "Opens mysql shell to current project database (${yellow}fin help sqlc${NC})"
	printh "sqls" "Show list of available databases (${yellow}fin help sqls${NC})"
	printh "sqld [file]" "Dump the database into a file (${yellow}fin help sqld${NC})"
	printh "sqli [file]" "Truncate the database and import from sql dump (${yellow}fin help sqli${NC})"

	echo
	printh "image <command>" "Image management" "yellow"
	printh "  save, load, registry" "See ${yellow}fin help image${NC} for details"

	echo
	printh "project <command>" "Project management" "yellow"
	printh "  list, create" "See ${yellow}fin help project${NC} for details"

	echo
	printh "ssh-add [-lD] [key]" "Adds private key identities to the authentication agent (${yellow}fin help ssh-add${NC})"
	printh "cleanup [--hard]" "Remove unused docker images and projects that are no longer present"

	echo
	printh "config" "Display/generate project configuration (${yellow}fin help config${NC})"
	printh "run-cli (rc) <command>" "Run a command in a standalone cli container in the current directory"
	printh "share" "Share web server of the current project on the internet using ngrok"
	printh "sysinfo" "Show diagnostics information for bug reporting"
	printh "alias" "Create/remove folder aliases (${yellow}fin help alias${NC})"
	printh "version (v, -v)" "Print fin version. [v, -v] - prints short version"
	printh "update" "${yellow}Update Docksal${NC}" "yellow"

	# Show list of custom commands and their help if available
	if [ ! -z "$(get_project_path)" ]; then
		show_help_list_of_custom_commands 'project'
	fi
	if [ ! -z "$HOME/$DOCKSAL_COMMANDS_PATH" ]; then
		show_help_list_of_custom_commands 'global'
	fi

	echo
}

# param $1 - 'project' or 'global'
show_help_list_of_custom_commands ()
{
	local _path
	if [[ "$1" == 'project' ]]; then
		_path="$(get_project_path)/$DOCKSAL_COMMANDS_PATH"
		# avoid taking global .docksal folder for project one
		if [[ "$_path" == "$HOME/$DOCKSAL_COMMANDS_PATH" ]]; then return; fi
	else
		_path="$HOME/$DOCKSAL_COMMANDS_PATH"
	fi

	custom_commands_list=$(ls "$_path" 2>/dev/null | tr "\n" " ")
	if [ ! -z "$custom_commands_list" ]; then
		echo
		echo -e "Custom commands found in ${yellow}$1 commands${NC}:";
		for cmd_name in $(ls "$_path")
		do
			# command description is lines that start with ##
			local cmd_desc=$(cat "$_path/$cmd_name" | grep '^##' | sed "s/^##[ ]*//g" | head -1 --)
			printh "$cmd_name" "$cmd_desc"
		done
	fi
}

show_help_ssh-add ()
{
	echo-green "fin ssh-add - Add private key identities to the ssh-agent."
	echo "Usage: fin ssh-add [-lD] [key]"
	echo
	echo "When run without arguments, picks up the default key files (~/.ssh/id_rsa, ~/.ssh/id_dsa, ~/.ssh/id_ecdsa)."
	echo "A custom key name can be given as an argument: fin ssh-add <keyname>."
	echo
	echo -e "${yellow}NOTE${NC}: <keyname> is the file name within ${yellow}~/.ssh${NC} (not full path to file)."
	echo "Example: fin ssh-add my_custom_key_rsa"
	echo
	echo "The options are as follows:"
	printh "-D" "Deletes all identities from the agent."
	printh "-l" "Lists fingerprints of all identities currently represented by the agent."
	echo
}

show_help_exec ()
{
	echo-green "fin exec [options] <command|file> - Execute command or file in ${yellow}cli${green} service container."
	echo
	echo "Command or file is a required parameter."
	echo "It will be executed in the path that matches your local current path."
	echo
	echo "Options:"
	printh "-T" "Disable pseudo-tty allocation."
	printh "" "Useful for non-interactive commands when output is saved into a variable for further comparison."
	printh "" "In a TTY mode the output may contain unexpected control symbols/etc."
	echo
	echo-green "Examples:"
	printh "fin exec ls -la" "Current directory listing"
	printh "fin exec \"ls -la > /tmp/list\"" "Execute advanced shell command with pipes or stdout redirects happening inside cli"
	printh "res=\$(fin exec -T drush st)" "Use -T switch to assign exec output to a variable"
	printh "fin exec .docksal/script.sh" "Execute file inside cli container"
	echo
}

show_help_reset ()
{
	printh "fin reset" "" "yellow"
	echo
	echo-green "Recreate services/containers. Equal to fin rm followed by fin start"
	echo "By default recreates project containers deleting all changes that were made to them."
	echo
	echo-green "System services"
	echo -e "Docksal has several system services."
	echo -e "Names ${yellow}'dns'${NC}, ${yellow}'proxy'${NC}, ${yellow}'ssh-agent'${NC} and ${yellow}'system'${NC} are reserved and should not be used in projects."
	echo
	printh "fin reset dns" "Recreate Docksal DNS service"
	printh "fin reset proxy" "Recreate Docksal HTTP/HTTPS reverse proxy service (resolves ${yellow}*.docksal${NC} domain names into container IPs)"
	printh "fin reset ssh-agent" "Recreate Docksal ssh-agent service"
	printh "fin reset system" "Recreate all Docksal system services"
	echo
}

show_help_rm ()
{
	echo-green "Remove services"
	printh "fin remove" "" "yellow"
	echo
	echo "Removes project containers and frees up space consumed by them."
	echo
}
show_help_remove ()
{
	show_help_rm
}

show_help_image() {
	echo-green "Image management"
	printh "fin image <command>" "" "yellow"
	echo
	printh "save [--system|--project|--all]" "Save docker images into a tar archive."
	printh "load <file>" "Load docker images from a tar archive."
	echo
	printh "registry" "Show all Docksal images on Docker Hub"
	printh "registry [image name]" "Show all tags for a certain image"
	echo
	echo-green "Examples:"
	printh "fin image save --system" "Save Docksal system images."
	printh "fin image save --project" "Save current project's images."
	printh "fin image save --all" "Save all images available on the host."
	printh "fin image registry docksal/db" "Show all tags for docksal/db image"
	echo
}

show_help_project() {
	echo-green "Project management"
	printh "fin project <command>" "" "yellow"
	echo
	printh "list (pl) [-a (--all)]" "List running Docksal projects (-a to show stopped as well)"
	printh "create" "Create and install new Drupal, Wordpress or Magento project."
	echo
	echo-green "Examples:"
	printh "fin pl -a" "List all known Docksal projects, including stopped ones"
	echo
}

show_help_update ()
{
	echo-green "fin update - Automated update of Docksal system components"
	echo
}

show_help_exec-url ()
{
	echo-green "fin exec-url <url> - Fetch script and evaluate locally"
	echo
	echo -e "URL is required parameter. Useful for demos or installations."
	echo
}

show_help_sqlc ()
{
	echo-green "Open mysql console to current db server (alias: mysql)"
	printh "fin sqlc" "" "yellow"
	echo
	echo-green "Parameters:"
	printh "--db-user=admin" "Use another mysql username (default is 'root')"
	printh "--db-password=p4\$\$" "Use another database password (default is the one set with 'MYSQL_ROOT_PASSWORD', see ${yellow}fin config${NC})"
	echo
}
show_help_mysql ()
{
	show_help_sqlc
}

show_help_sqls ()
{
	echo-green "Show list of available databases (alias: mysql-list)"
	printh "fin sqls" "" "yellow"
	echo
	echo-green "Parameters:"
	printh "--db-user=admin" "Use another mysql username (default is 'root')"
	printh "--db-password=p4\$\$" "Use another database password (default is the one set with 'MYSQL_ROOT_PASSWORD', see ${yellow}fin config${NC})"
	echo
}
show_help_mysql_list ()
{
	show_help_sqls
}

show_help_sqli ()
{
	echo-green "Truncate database and import dump from file or stdin (alias: mysql-import)"
	printh "fin sqli [dump_file.sql]" "" "yellow"
	echo
	echo -e "DB dump file should be plain ${yellow}.sql${NC} file."
	echo
	echo-green "Parameters:"
	printh "--force" "Do not ask questions. The only time when question is asked is when truncation fails."
	printh "--db=drupal" "Use another database (default is the one set with 'MYSQL_DATABASE')"
	printh "--db-user=admin" "Use another mysql username (default is 'root')"
	printh "--db-password=p4\$\$" "Use another database password (default is the one set with 'MYSQL_ROOT_PASSWORD', see ${yellow}fin config${NC})"
	echo
	echo-green "Examples:"
	printh "fin sqli ~/dump.sql --db=drupal" "	Import plaintext sql dump into database named 'drupal' (DB should exist)"
	printh "cat ~/dump.sql | fin sqli" "	Import dump from stdin into default database"
	echo
}
show_help_mysql-import ()
{
	show_help_sqli
}

show_help_sqld ()
{
	echo-green "Export database from db container into file or stdout (alias: mysql-dump)"
	printh "fin sqld [dump_file]" "" "yellow"
	echo
	echo-green "Parameters:"
	printh "--db=drupal" "Use another database (default is the one set with 'MYSQL_DATABASE')"
	printh "--db-user=admin" "Use another mysql username (default is 'root')"
	printh "--db-password=p4\$\$" "Use another database password (default is the one set with 'MYSQL_ROOT_PASSWORD', see ${yellow}fin config${NC})"
	echo
	echo-green "Examples:"
	printh "fin sqld ~/dump.sql" "Export default database dump"
	printh "fin sqld --db=drupal" "Export database 'drupal' dump into stdout"
	echo
}
show_help_mysql-dump ()
{
	show_help_sqld
}

show_help_vm ()
{
	echo-green "Control docker machine directly"
	printh "fin vm <command>" "" "yellow"
	echo
	echo-green "Commands:"
	printh "start" "Start a machine (create if needed)"
	printh "stop" "Stop active machine"
	printh "kill" "Forcibely stop active machine"
	printh "restart" "Restart a machine"
	printh "status" "Get the status of a machine"
	printh "ls" "List all docker machines"
	printh "ssh" "Log into or run a command on the active machine with SSH"
	printh "remove" "Remove active machine"
	printh "ip" "Get machine IP address"
	# printh "ip [new ip]" "Set machine IP address (requires vm restart)"
	printh "env" "Display the commands to set up the shell for direct use of Docker client"
	echo
	printh "mount" "Try remounting host filesystem (NFS on macOS, SMB on Windows)"
	printh "ram" "Get machine memory size"
	printh "ram [megabytes]" "Set machine memory size. Default is 1024 (requires vm restart)"
	printh "stats" "Show machine HDD/RAM usage stats"
	echo
}

show_help_alias ()
{
	echo-green "fin alias - Create/delete aliases"
	echo
	echo "Aliases provide functionality that is similar to drush aliases."
	echo "Using alias you are able to execute a command for a project without navigating to the project folder."
	echo "You can precede any command with an alias."
	echo
	echo-green "Usage:"
	printh "fin alias [list]" "Show aliases list"
	printh "fin alias <path> <alias_name>" "Create an alias that links to target path"
	printh "fin alias remove <alias_name>" "Remove alias"
	echo-green "Examples:"
	printh "fin alias ~/site1/docroot dev" "Create alias ${yellow}dev${NC} that is linked to ${yellow}~/site1/docroot${NC}"
	printh "fin @dev drush st" "Execute 'drush st' command in directory linked by ${yellow}dev${NC} alias"
	printh "" "Hint: create alias to Drupal sub-site folder to launch subsite targeted commands"
	printh "fin alias remove dev"	"Delete ${yellow}dev${NC} alias"
	echo
	echo "Aliases are effectively symlinks stored in $CONFIG_ALIASES"
}

show_help_share ()
{
	echo-green "Share project to the internet via ngrok"
	printh "fin share" "" "yellow"
	echo
	echo-green "Purpose:"
	echo "	In certain cases you may need to share or expose you local web server on the internet."
	echo "	E.g. share access with a teammate or customer to demonstrate the work or discuss the progress."
	echo "	ngrok creates a tunnel from the public internet to a port on your local machine even if you are behind NAT."
	echo
	echo-green "Usage:"
	echo "	You will get public web address in command line UI."
	echo -e "	Press ${yellow}Ctrl+C${NC} to stop sharing and quit command line UI"
	echo
}

show_help_config ()
{
	echo-green "Display/generate project configuration"
	printh "fin config [command]" "" "yellow"
	echo
	echo-green "Config commands:"
	printh "show" "Display full effective configuration for the project"
	printh "env" "Display only environment variables section"
	printh "generate" "Generate Docksal configuration for the project"
	echo
}

show_help_cleanup ()
{
	echo-green "Perform a cleanup"
	printh "fin cleaup [--hard]" "" "yellow"
	echo
	printh "Removes unused docker images to save disk space on VM."
	printh "Removes orphaned containers. Orphaned are those, which folders were deleted on filesystem"
	printh "without removing their containers with 'fin rm' first."
	echo-green "Parameters:"
	printh "--hard" "Also remove all stopped containers (potentially destructive operation)"
	echo
}

# Display fin version
# @option --short - Display only the version number
version ()
{
	if [[ $1 == '--short' ]]; then
		echo "$FIN_VERSION"
	else
		echo "fin version: $FIN_VERSION"
	fi

	# Ping stats server
	stats_ping
}

# return bash completion words
# @param $1 command to return words for
bash_comp_words ()
{
	case $1 in
		vm)
			echo "start restart status stop ssh stats kill remove ip ram"
			exit 0
			;;
		alias)
			echo "list remove"
			exit 0
		;;
		config)
			echo "generate show env"
			exit 0
			;;
		fin)
			local aliases=$(ls -l "$CONFIG_ALIASES" 2>/dev/null | grep -v total | awk '{printf "@%s ", $9}')
			local projects=$(docker ps --all \
				--filter 'label=com.docker.compose.service=web' \
				--format '@{{.Label "com.docker.compose.project"}}' | xargs
			)
			echo "$aliases $projects vm start stop restart status reset remove bash exec config create-site sqlc mysql sqli mysql-import sqld mysql-dump sqld drush drupal \
			ssh-add update version cleanup sysinfo logs"
			exit 0
			;;
		*)
			exit 1 #return 1 to completion function to prevent completion if we don't know what to do
	esac
}

#------------------------------- Docker-Machine -----------------------------------

is_docker_machine_running ()
{
#	check_binary_found 'docker-machine'
#	docker-machine status "$DOCKER_MACHINE_NAME" 2>/dev/null | grep "Running" 2>&1 1>/dev/null
	[[ "$DOCKER_MACHINE_STATUS" == 'Running' ]]
}

# Create docker machine
# param $1 machine name
docker_machine_create ()
{
	check_vbox_version
	check_binary_found 'docker-machine'

	local machine_name="${1:-$DEFAULT_MACHINE_NAME}"

	if is_docker_machine_exist "$machine_name"; then
		echo-error "Docker Machine '$machine_name' already exists"
		return 1
	fi

	echo-green "Creating docker machine '$machine_name'..."

	# Use a local boot2docker.iso copy when available
	ISO_FILE=${ISO_FILE:-boot2docker.iso}
	if [[ -f "$ISO_FILE" ]]; then
		echo "Found $ISO_FILE. Using it..."
		URL_BOOT2DOCKER="$ISO_FILE"
	fi

	docker-machine create \
 		--driver=virtualbox \
		--virtualbox-boot2docker-url "$URL_BOOT2DOCKER" \
		--virtualbox-disk-size "$DEFAULT_MACHINE_VBOX_HDD" \
		--virtualbox-memory "$DEFAULT_MACHINE_VBOX_RAM" \
		--virtualbox-hostonly-cidr "$DOCKSAL_DEFAULT_SUBNET" \
		--virtualbox-no-share \
		"$machine_name"

	if [[ $? -eq 0 ]]; then
		DOCKER_MACHINE_NAME="$machine_name"
		DOCKER_MACHINE_STATUS='Running'
		vm active "$machine_name"
	else
		return 1
	fi
}

# Param $1 machine name (defaults to $DOCKER_MACHINE_NAME)
# Param $2 refresh machine status true|false (defaults to false)
is_docker_machine_exist ()
{
	local refresh="${2:-false}"

	! which 'docker-machine' >/dev/null 2>&1 && return 1
	if [[ "$1" != "" ]] && [[ "$1" != "$DOCKER_MACHINE_NAME" ]]; then
		docker-machine ls | grep "$1" >/dev/null 2>&1
	else
		if [[ "$refresh" == "true" ]]; then
			# Refresh VM status in case in changed while the script was running.
			DOCKER_MACHINE_STATUS=$(docker-machine status "$DOCKER_MACHINE_NAME" 2>&1 || echo '')
		fi
		[[ "$DOCKER_MACHINE_STATUS" == *"not exist"* ]] && return 1 || return 0
	fi
}

# Return docker machine provider
docker_machine_provider ()
{
	# For now always return virtualbox
	# TODO: remove if not used in September 2017
	echo 'virtualbox'
	#docker-machine ls | grep "$DOCKER_MACHINE_NAME" | awk '{print $3}' 2>/dev/null
}

docker_machine_env ()
{
	#remove cache
	rm -f "$CONFIG_MACHINES_ENV" 2>/dev/null
	local _env=$(docker-machine env --shell=bash "$DOCKER_MACHINE_NAME")
	eval ${_env}
	# Save to file for reuse during subsequent fin runs to avoid running env which is expensive
	echo "${_env}" | tee "$CONFIG_MACHINES_ENV" >/dev/null
}

# Stop docker machine
docker_machine_stop ()
{
	check_binary_found 'docker-machine'
	docker-machine stop "$DOCKER_MACHINE_NAME"
}

docker_machine_change_ip ()
{
	echo "(docksal) Applying IP address $DOCKER_MACHINE_IP"
	# extract first three parts of IP and append 255 to get broadcast mask
	local BROADCAST_MASK=`expr "$DOCKER_MACHINE_IP" : '\([0-9][0-9]*[0-9]*\.[0-9][0-9]*[0-9]*\.[0-9][0-9]*[0-9]*\.\)'`'255';
	docker-machine ssh "$DOCKER_MACHINE_NAME" "sudo cat /var/run/udhcpc.eth1.pid | xargs sudo kill" && \
		docker-machine ssh "$DOCKER_MACHINE_NAME" "sudo ifconfig eth1 $DOCKER_MACHINE_IP netmask 255.255.255.0 broadcast $BROADCAST_MASK up" && \
		sleep 2 && \
		docker-machine regenerate-certs "$DOCKER_MACHINE_NAME" -f
	sleep 2
	local i=0
	local _logs=""
	for i in `seq 20`; do
		_logs=$(docker-machine env "$DOCKER_MACHINE_NAME" 2>&1)
		if [[ $? -eq 0 ]]; then return; fi
		echo "IP validation (attempt #${i})..."
		sleep 3
	done
	echo "$_logs"
	return 1
}

docker_machine_start ()
{
	check_binary_found 'docker-machine'

	if is_docker_machine_exist; then
		docker-machine start "$DOCKER_MACHINE_NAME" && DOCKER_MACHINE_STATUS='Running' && \
			# Disable IP change for now
			#docker_machine_change_ip && \
			docker_machine_env && \
			docker_machine_mounts
	else
		# only auto-create default machine
		if [[ "$DOCKER_MACHINE_NAME" != "$DEFAULT_MACHINE_NAME" ]]; then
			echo-error "Machine '$DOCKER_MACHINE_NAME' does not exist"
			echo-yellow "Removing reference to non-existent machine... Run your command again."
			rm -f "$CONFIG_MACHINE_ACTIVE"
			exit 1
		fi

		docker_machine_create && \
			# Disable IP change for now
			#docker_machine_change_ip && \
			docker_machine_env
		[[ $? != 0 ]] && _docker_machine_start_exception

		echo-green "Pulling Docksal system images..."
		update_system_images
		docker_machine_mounts
	fi

	# Catch the return code from docker_machine_mounts
	# TODO: figure out a more reliable implementation, as this may break if the code above gets reordered
	local _err=$?
	if [[ ${_err} -eq 0 ]]; then
		echo-green "Importing ssh keys..."
		ssh_add
	fi

	return ${_err}
}

# Displays an error message and offers to remove the vm if something failed
_docker_machine_start_exception ()
{
	echo-error "Proper creation of virtual machine has failed" \
				"For details please refer to the log above." \
				"${yellow}It is recommended to remove malfunctioned virtual machine.${NC}"
	docker_machine_remove
	exit 1
}

# param $1 machine name (defaults to $DOCKER_MACHINE_NAME)
docker_machine_remove ()
{
	local machine_name="${1:-$DOCKER_MACHINE_NAME}"

	_confirm "Remove $machine_name?"
	# VirtualBox
	if [[ "$(docker_machine_provider)" == 'virtualbox' ]]; then
		# Store host-only interface name before removing the VM.
		local vboxifname=$("$vboxmanage" showvminfo "$machine_name" 2>/dev/null | grep "Host-only" | sed "s/.*Host-only.*'\(.*\)'.*/\1/g")
		docker-machine rm -f "$machine_name"
		if ! is_docker_machine_exist "$machine_name" "true"; then
			# If the VM was removed, remove the DHCP server associated with its network interface.
			# This ensures that we always get the lower bound IP address from the DHCP address pool (i.e., ".100").
			"$vboxmanage" dhcpserver remove --netname "HostInterfaceNetworking-${vboxifname}" >/dev/null 2>&1
			# Killing the network interface also helps to avoid issues when VM is recreated.
			"$vboxmanage" hostonlyif remove "$vboxifname" >/dev/null 2>&1
		fi

		if is_windows; then
			echo-green "Removing SMB shares..."
			docker_machine_remove_smb
		fi
		if is_mac; then
			echo-green "Removing NFS exports..."
			docker_machine_remove_nfs
		fi
	else
		docker-machine rm -f "$machine_name"
	fi
}

# Mount folder inside docker-machine with NFS
# Unnamed params - shares in format "$LOCAL_FOLDER:$MOUNT_POINT_NAME"
# Named --no-export param(s) - will try to mount those mount points without exporting $LOCAL_FOLDER
docker_machine_mount_nfs ()
{
	local machine_name="$DOCKER_MACHINE_NAME"
	local network_name
	local nfs_ip
	eval $(parse_params "$@")

	# Get required IP addresses
	network_name=$("$vboxmanage" showvminfo "$machine_name" --machinereadable | grep hostonlyadapter | cut -d \" -f2)
	if [[ "$network_name" == "" ]]; then
		echo-error "Could not find virtualbox net name." && exit 1
	fi
	# nfs_ip is an internal IP of localhost as docker machine sees it.
	nfs_ip=$("$vboxmanage" list hostonlyifs | grep "$network_name" -A 3 | grep IPAddress | cut -d ':' -f2 | xargs)
	if [[ "$nfs_ip" == "" ]]; then
		echo-error "Could not find virtualbox internal net IP address." && exit 1
	fi
	machine_ip=$(docker-machine ip "$machine_name")

	# Remove our own old exports
	local exports_open="# <ds-nfs $machine_name"
	local exports_close="# ds-nfs>"
	local exports=$(cat /etc/exports 2>/dev/null | \
		tr "\n" "\r" | \
		sed "s/${exports_open}.*${exports_close}//" | \
		tr "\r" "\n"
	)

	# Prepare new exports file
	exports="${exports}\n${exports_open}\n"
	for share in ${ARGV[@]}; do
		local share_export=(${share//:/ });
		# TODO: move exports into a separate function and make it work with D4M with or without VirtualBox.
		exports="${exports}$share_export 127.0.0.1 $machine_ip -alldirs -maproot=0:0\n"
	done
	exports="${exports}${exports_close}"

	local new_exports=$(echo -e "$exports")
	local old_exports=$(cat /etc/exports 2>/dev/null)
	if [[ "$new_exports" != "$old_exports" ]]; then
		# Write temporary exports file to /tmp/etc.exports.XXXXX and check it
		local exports_test="/tmp/etc.exports.$RANDOM"
		echo -e "$exports" | tee "$exports_test" >/dev/null
		exports_errors=$(nfsd -F "$exports_test" checkexports 2>&1)
		rm -f "$exports_test" >/dev/null 2>&1

		# Do not write /etc/exports if there are config check errors
		if [[ "$exports_errors" != '' ]]; then
			echo-error "$exports_errors"
			echo "-----------------"
			echo -e "$exports"
			echo "-----------------"
			return 1
		fi

		echo "Writing /etc/exports..."
		echo -e "$exports" | sudo tee /etc/exports >/dev/null

		NFSD_RESTART_REQUIRED="true"
	else
		# /etc/export already contains what is required
		echo "NFS shares are already configured"
	fi

	# Start/Restart nfsd
	(ps aux | grep /sbin/nfsd | grep -v grep >/dev/null) && NFSD_IS_RUNNING="true"
	if [[ "$NFSD_IS_RUNNING" == "true" ]]; then
		if [[ "$NFSD_RESTART_REQUIRED" == "true" ]]; then
			echo-green "Restarting nfsd..."
			sudo nfsd restart
			sleep 5
		fi
	else
		echo-green "Starting nfsd..."
		sudo nfsd start
		sleep 10
	fi

	# Mount exported folders
	echo-green "Mounting NFS shares..."
	# Start NFS client on docker-machine
	docker-machine ssh "$machine_name" \
		"sudo /usr/local/etc/init.d/nfs-client start"
	for share in ${ARGV[@]}; do
		local share_=(${share//:/ });
		local share_export="${share_[0]}"
		local share_mount="${share_[1]}"
		# Add new exports
		echo "Mounting local $share_export to $share_mount"
		docker-machine ssh "$machine_name" \
			"sudo mkdir -p $share_mount ;
			sudo umount $share_mount 2>/dev/null ;
			sudo mount -t nfs -o nolock,noacl,nocto,noatime,nodiratime,actimeo=1 $nfs_ip:$share_export $share_mount"
			# [!!] Think twice about performance before changing nfs settings
		if [ ! $? -eq 0 ]; then
			echo "Retrying mounting local $share_export to $share_mount"
			sleep 5
			docker-machine ssh "$machine_name" \
				"sudo mount -t nfs -o nolock,noacl,nocto,noatime,nodiratime,actimeo=1 $nfs_ip:$share_export $share_mount"
			[ ! $? -eq 0 ] &&
				echo-red "NFS share mount has failed. Try fin vm restart."
		fi
	done

}

docker_machine_remove_nfs ()
{
	local machine_name="$DOCKER_MACHINE_NAME"
	# Remove our own old exports
	local exports_open="# <ds-nfs $machine_name"
	local exports_close="# ds-nfs>"
	local exports=$(cat /etc/exports 2>/dev/null | \
		tr "\n" "\r" | \
		sed "s/${exports_open}.*${exports_close}//" | \
		tr "\r" "\n"
	)

	# Write temporary exports file to /tmp/etc.exports.XXXXX and check it
	local exports_test="/tmp/etc.exports.$RANDOM"
	echo -e "$exports" | tee "$exports_test" >/dev/null
	exports_errors=$(nfsd -F "$exports_test" checkexports 2>&1)
	rm -f "$exports_test" >/dev/null 2>&1

	# Do not write /etc/exports if there are config check errors
	if [[ "$exports_errors" != '' ]]; then
		echo-error "$exports_errors"
		echo "-----------------"
		echo -e "$exports"
		echo "-----------------"
		return 1
	fi

	echo "Writing and applying /etc/exports..."
	echo -e "$exports" | sudo tee /etc/exports >/dev/null
	sudo nfsd restart
	sleep 2
}

# Fix/optimize Windows network settings for file sharing.
# See http://serverfault.com/a/236393 for details.
smb_windows_fix()
{
	! is_windows && return

	echo-green "Going to optimize Windows network settings for file sharing..."
	echo "You may see an elevated command prompt - click Yes."
	sleep 2

	local tmpfile="/tmp/fix-smb.reg"
	cat <<EOF > $tmpfile
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management]
"LargeSystemCache"=dword:00000001

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\LanmanServer\Parameters]
"Size"=dword:00000003
EOF
	# Update registry and restart Server and Computer Browser services.
	winsudo "regedit /S $(cygpath -w ${tmpfile}) && net stop server /y && net start server && net start browser"
}

# Method to create the user and SMB network share on Windows.
# @param share_name, path
smb_share_add()
{
	# Add SMB share if it does not exist.
	if [[ "$(net share)" != *"${1}"*"Docksal ${2} drive"* ]];
	then
		command_share="net share ${1}=${2} /grant:${USERNAME},FULL /REMARK:\"Docksal ${2} drive\""
		echo-green "Adding docker SMB share..."
		winsudo "$command_share"
	fi
}

# Method to mount the SMB share in Docker machine.
# @param share_path, mount_point, password
smb_share_mount()
{
	#DOCKER_MACHINE_IP=$(docker-machine ip ${DOCKER_MACHINE_NAME})
	network_id=$("$vboxmanage" showvminfo ${DOCKER_MACHINE_NAME} --machinereadable | grep hostonlyadapter | cut -d'"' -f2)
	DOCKER_HOST_IP=$("$vboxmanage" list hostonlyifs | grep "${network_id}$" -A 3 | grep IPAddress |cut -d ':' -f2 | xargs)

	command_mount="sudo mkdir -p $2 && sudo mount -t cifs -o username='${USERNAME}',pass='$3',sec=ntlm,nobrl,mfsymlinks,noperm,actimeo=1,dir_mode=0777,file_mode=0777 //${DOCKER_HOST_IP}/$1 $2"
	docker-machine ssh ${DOCKER_MACHINE_NAME} "$command_mount"
}

docker_machine_mount_smb ()
{
	# add share \\hostname\c writable to current user
	# ask user for his password
	# use his password for mount -t cifs ...

	# Get a list of logical drives (type 3 = Local disk).
	local DRIVES=$(wmic logicaldisk get drivetype,name | grep 3 | awk '{print $2}' | sed 's/\r//g')
	read -s -p "Enter your Windows account password: " PASSWORD
	echo # Add a new line after user input.

	for DRIVE in ${DRIVES}; do
		local MOUNT_POINT=$(cygpath -u "$DRIVE" | sed 's/^\/cygdrive\///')
		smb_share_add "$MOUNT_POINT" "$DRIVE" && \
			smb_share_mount "$MOUNT_POINT" "/$MOUNT_POINT" "$PASSWORD" || \
			(echo-red "Error creating share" && exit 1)
	done
}

docker_machine_remove_smb ()
{
	local DRIVES=$(wmic logicaldisk get drivetype,name | grep 3 | awk '{print $2}' | sed 's/\r//g')
	for DRIVE in ${DRIVES}; do
		local MOUNT_POINT=$(cygpath -u "$DRIVE" | sed 's/^\/cygdrive\///')
		command_share="net share ${MOUNT_POINT} /DELETE"
		winsudo "$command_share"
	done
}

docker_machine_mounts ()
{
	if [[ "$(docker_machine_provider)" == 'virtualbox' ]]; then
		if is_mac; then
			echo-green "Configuring NFS shares..."
			docker_machine_mount_nfs "/Users:/Users"
		elif is_windows; then
			echo-green "Configuring SMB shares..."
			docker_machine_mount_smb
		fi
	fi
}

#------------------------------- VM Commands -----------------------------------

vm ()
{
	if is_docker_native; then
		return
	fi

	check_binary_found 'docker-machine'

	if ! is_docker_machine_exist && [[ "$1" != "" ]] && [[ "$1" != "start" ]] && [[ "$1" != "create" ]] && [[ "$1" != "ls" ]] && [[ "$1" != "remove" ]] && [[ "$1" != "rm" ]] && [[ "$1" != "active" ]] ; then
		 echo-yellow "Docker machine $DOCKER_MACHINE_NAME is not created. Use 'fin vm start' or 'fin up'."
		 return 1
	fi

	case $1 in
		create)
			# usage: fin vm create <machine_name>
			shift
			# errors handling
			[[ "$1" == "" ]] && echo "Please provide a name for a new vm." && return 1
			is_docker_machine_exist "$1" && echo "Machine ${1} already exists." && return 1
			# create
			docker_machine_create "$1"
			;;
		active)
			# Get/Set active vm
			shift
			if [[ "$1" == "" ]]; then
				echo "$DOCKER_MACHINE_NAME ($(docker_machine_provider))"
			else
				[[ "$1" == "$DOCKER_MACHINE_NAME" ]] && echo "$1 is already active" && return 0
				! is_docker_machine_exist "$1" && echo "No docker machine with name $1" && return 1
				mkdir -p "$CONFIG_MACHINES" || return 1
				echo "$1" | tee "$CONFIG_MACHINE_ACTIVE" >/dev/null && echo "$1 is set active"
			fi
			;;
		start)
			if is_docker_machine_running; then
				echo "Machine \"$DOCKER_MACHINE_NAME\" is already running."
			else
				docker_machine_start
			fi
			;;
		restart)
			docker_machine_stop; docker_machine_start
			;;
		status)
			shift
			local machine_name="${1:-$DOCKER_MACHINE_NAME}"
			docker-machine status "$machine_name"
			;;
		stop)
			docker_machine_stop
			;;
		ssh)
			shift
			docker-machine ssh "$DOCKER_MACHINE_NAME" "$@"
			;;
		stats)
			vm-stats
			;;
		kill)
			shift
			local machine_name="${1:-$DOCKER_MACHINE_NAME}"
			docker-machine kill "$machine_name"
			;;
		ls|list)
			docker-machine ls
			;;
		remove|rm)
			shift
			local machine_name="${1:-$DOCKER_MACHINE_NAME}"
			docker_machine_remove "$machine_name"
			;;
		mount)
			docker_machine_mounts
			;;
		ip)
			shift
			local machine_name="${1:-$DOCKER_MACHINE_NAME}"
			if [[ "$1" =~ [0-9][0-9]*[0-9]*.[0-9][0-9]*[0-9]*\.[0-9][0-9]*[0-9]*\.[0-9] ]]; then
				# set ip
				echo-green "Setting ip to $1..."
#				echo "$1" > "$DOCKER_MACHINE_FOLDER/ip"
#				echo-yellow "IP change will take effect on next machine start."
				DOCKER_MACHINE_IP="$1"
				docker_machine_change_ip
			else
				docker-machine ip "$machine_name"
			fi

			;;
		env)
			shift
			DOCKER_MACHINE_NAME="${1:-$DOCKER_MACHINE_NAME}"
			docker_machine_env
			;;
		ram)
			shift
			vm-ram "$@"
			;;
		*)
			echo-error "Unknown command fin vm $1" "See ${yellow}fin help vm${NC} for list of available commands"
			;;
	esac
}

vm-stats ()
{
	[[ "$(docker_machine_provider)" != 'virtualbox' ]] && echo "This command is for virtualbox machines only" && exit 1
	check_docker_running # should be running
	check_vbox_version
	metrics="CPU/Load/User,CPU/Load/Kernel,Disk/Usage/Used,RAM/Usage/Used,Net/Rate/Rx,Net/Rate/Tx"
	"$vboxmanage" metrics setup --period 1 --samples 1 "$DOCKER_MACHINE_NAME"
	sleep 1
	"$vboxmanage" metrics query "$DOCKER_MACHINE_NAME" "$metrics"
}

vm-ram () {
	[[ "$(docker_machine_provider)" != 'virtualbox' ]] && echo "This command is for virtualbox machines only" && exit 1
	echo "Current $("$vboxmanage" showvminfo "$DOCKER_MACHINE_NAME" | grep Memory)"
	if [[ "$1" != "" ]]; then
		local running
		is_docker_machine_running && running=1
		_confirm "Continue changing Memory size to ${1}MB?"
		[[ ${running} == 1 ]] && docker_machine_stop
		"$vboxmanage" modifyvm "$DOCKER_MACHINE_NAME" --memory "$1" && \
			echo "Memory size updated."
		[[ ${running} == 1 ]] && docker_machine_start
	fi
}

#------------------------------- Other Commands -----------------------------------

# Start containers
up ()
{
	check_docksal_environment
	# Run ssh_add here, since there is no better place to get it triggered on Linux.
	# This should not be the last command in a function as it will exit 1 on non Linux systems.
	is_linux && ssh_add
	check_project_unique

	_start_containers
}

# Stop containers
stop ()
{
	# Do not do any checks for "stop all projects" action
	if [[ $1 == '-a' ]] || [[ $1 == '--all' ]]; then
		_stop_containers "$@"
		# TODO: set stopped state to all projects
		return $?
	fi

	check_docksal_environment
	check_project_unique

	_stop_containers "$@"
}

# Restart container(s)
# @param $1 container_name
restart ()
{
	check_docksal_environment
	# Run ssh_add here, since there is no better place to get it triggered on Linux.
	# This should not be the last command in a function as it will exit 1 on non Linux systems.
	is_linux && ssh_add
	check_project_unique

	_restart_containers
}

# Remove container(s)
# @param $1 $2... container names
remove ()
{
	check_docksal_environment
	check_project_unique

	if [[ $1 == "" ]]; then
		echo -e "${red}WARNING:${NC} ${yellow}All containers and volumes for the current project will be removed!${NC}"
		_confirm "Continue?";
	fi

	# support quiet removal
	if [[ $1 == "-f" ]]; then
		shift
	fi

	_remove_containers "$@"
}

# List project containers
project_status ()
{
	check_docksal_environment
	check_project_unique

	docker-compose ps
}

# List Docksal projects
# @param $1 Show containers from all projects (-a)
project_list ()
{
	local all
	if [[ "$1" == "-a" ]] || [[ "$1" == "--all" ]]; then
		all="--all"
	fi
	check_docker_running
	docker ps ${all} \
		--filter 'label=com.docker.compose.service=web' \
		--format 'table {{.Label "com.docker.compose.project"}}\t{{.Status}}\t{{.Label "io.docksal.virtual-host"}}\t{{.Label "io.docksal.project-root"}}'
}

project_create ()
{
	while true; do
		read -p "Please enter the name of your project (all one word, no spaces or slashes): " project_name
		if [[ "$project_name" =~ [^a-zA-Z0-9_-] ]]; then
			echo-red "Please provide a valid project name (only letters, numbers, dashes, and underscores are permitted)."
			continue
		fi
		break
	done
	echo ''

	echo -e "What would you like to install?"
	echo -e "${green}[1]${NC} Drupal 7"
	echo -e "${green}[2]${NC} Drupal 8"
	echo -e "${green}[3]${NC} Wordpress"
	echo -e "${green}[4]${NC} Magento"
	echo -e ""
	while true; do
		read -p ": " choice
		case ${choice} in
			1)
				target_cms="Drupal 7"
				target_host_name_search_string="drupal7"
				target_repo="$URL_REPO_DRUPAL7"
				break
				;;
			2)
				target_cms="Drupal 8"
				target_host_name_search_string="drupal8"
				target_repo="$URL_REPO_DRUPAL8"
				break
				;;
			3)
				target_cms="Wordpress"
				target_host_name_search_string="wordpress"
				target_repo="$URL_REPO_WORDPRESS"
				break
				;;
			4)
				target_cms="Magento"
				target_host_name_search_string="magento"
				target_repo="$URL_REPO_MAGENTO"
				break
				;;
			* )
				echo 'Please enter 1, 2, 3 or 4.'
				continue
		esac
		break
	done
	echo ''

	echo -e "Your site will be created at ${yellow}$(pwd)/$project_name${NC}"
	echo -e "Your site will run ${yellow}${target_cms}${NC}"
	echo -e "The URL of your site will be ${yellow}http://$project_name.docksal${NC}"
	echo ''

	_confirm "Do you wish to proceed?"

	echo -e "${green} Cloning repository...${NC}"
	git clone -b master ${target_repo} ${project_name}
	[ ! $? -eq 0 ] && _confirm "Checkout finished with errors. Do you wish to continue?"

	cd ${project_name}/.docksal &&
		# Edit docksal.env to use a custom user-supplied host name
		sed -i.bak "s/VIRTUAL_HOST=${target_host_name_search_string}/VIRTUAL_HOST=${project_name}/g" docksal.env && rm docksal.env.bak > /dev/null 2>&1 &&
		cd ".." &&
		fin init
}

# Add key to ssh-agent or run ssh-add with provided @param
# @param $1 -D, -l or path to custom key
ssh_add () {
	check_winpty_found

	# Check if ssh-agent container is running
	local running=$(docker inspect --format="{{ .State.Running }}" docksal-ssh-agent 2>/dev/null)
	[[ "$running" != "true" ]] && return

	local ssh_path="$HOME/.ssh"
	local key_path=""

	# When no arguments provided, check if ssh-agent already has at least one identity. If so, stop here.
	docker exec docksal-ssh-agent ssh-add -l >/dev/null
	if [[ $1 == "" && $? == 0 ]]; then return; fi

	# $ssh_path should be mounted as /.ssh in the ssh-agent containers.
	# When $key_path is empty, ssh-agent will be looking for both id_rsa and id_dsa in the home directory.
	if is_tty; then
		# Run ssh-add interactively to allow entering a passphrase for ssh keys (if set)
		${winpty} docker run --rm -it -v=docksal_ssh_agent:/.ssh-agent -v "$ssh_path:/.ssh:ro" "${IMAGE_SSH_AGENT}" ssh-add "$@"
	else
		# In a non-interactive environment (e.g. CI) run non-interactively. Keys with passphrases cannot be used!
		echo-yellow "Running in a non-interactive environment. SSH keys with passphrases cannot be used."
		docker run --rm -v=docksal_ssh_agent:/.ssh-agent -v "$ssh_path:/.ssh:ro" "${IMAGE_SSH_AGENT}" ssh-add "$@"
	fi
	return $?
}

#----- Installations and updates -----

# Reports version stats
stats_ping ()
{
	[[ "$DOCKSAL_STATS_OPTOUT" != 0 ]] && return # Don't run if the user opted out
	[[ "$CI" == "true" ]] && return # Don't run in CI

	# We are passing OS version via a custom User-Agent request header, which GA can parse
	local user_agent
	is_linux && user_agent="fin/${FIN_VERSION} (Linux $(lsb_release -si)-$(lsb_release -sr))"
	is_mac && user_agent="fin/${FIN_VERSION} (Macintosh Intel Mac OS X $(sw_vers -productVersion))"
	is_windows && user_agent="fin/${FIN_VERSION} (Windows NT $(echo $(cmd /c ver) | sed 's/.*Version \(.*\)\..*]/\1/'))"

	curl -kfsL \
		--user-agent "$user_agent" \
		--data "v=1&tid=${DOCKSAL_STATS_TID}&cid=${DOCKSAL_UUID}&t=screenview&an=fin&av=${FIN_VERSION}&cd=ping" \
		"${DOCKSAL_STATS_URL}" >/dev/null 2>&1 &

	return 0
}

install_proxy_service ()
{
	docker rm -f docksal-vhost-proxy >/dev/null 2>&1 || true
	docker volume rm docksal_projects >/dev/null 2>&1 || true

	# Create a bind mount volume to the projects directory if defined. If not - create an empty volume.
	local volume_options=""
	[[ "$PROJECTS_ROOT" != "" ]] && [[ -d "$PROJECTS_ROOT" ]] && \
		# Don't use quotes with the device option or the bind mount will not work
		volume_options="--opt type=none --opt device=$PROJECTS_ROOT --opt o=bind"
	docker volume create --name docksal_projects $volume_options >/dev/null 2>&1

	# PROJECT_INACTIVITY_TIMEOUT, PROJECT_DANGLING_TIMEOUT and PROJECTS_ROOT (docksal_projects volume) are used in CI
	# and are inactive unless configured.
	# PROJECT_INACTIVITY_TIMEOUT - defines the timeout of inactivity after which the project stack will be stopped (e.g. 0.5h)
	# PROJECT_DANGLING_TIMEOUT - defines the timeout of inactivity after which the project stack and code base will be
	# entirely wiped out from the host (e.g. 168h). WARNING: use at your own risk!
	docker run -d --name docksal-vhost-proxy --label "io.docksal.group=system" --restart=always \
		-p "${DOCKSAL_VHOST_PROXY_PORT_HTTP:-80}":80 -p "${DOCKSAL_VHOST_PROXY_PORT_HTTPS:-443}":443 \
		-e PROJECT_INACTIVITY_TIMEOUT="${PROJECT_INACTIVITY_TIMEOUT:-0}" \
		-e PROJECT_DANGLING_TIMEOUT="${PROJECT_DANGLING_TIMEOUT:-0}" \
		-v docksal_projects:/projects \
		-v /var/run/docker.sock:/var/run/docker.sock \
		"${IMAGE_VHOST_PROXY}" >/dev/null
}

# @param $1 ip address defaults to 0.0.0.0
install_dns_service ()
{
	# Use default DNS on Linux and VirtualBox's buit-in DNS if using boot2docker
	local dns
	local ip="${1:-0.0.0.0}"
	if is_linux; then dns="$DOCKSAL_DEFAULT_DNS_NIX"; else dns="$DOCKSAL_DEFAULT_DNS"; fi

	# Support for boot2docker-vagrant
	local docker_ip_map="-p 172.17.42.1:53:53/udp"
	if is_linux; then docker_ip_map=""; fi

	docker rm -f docksal-dns >/dev/null 2>&1 || true
	docker run -d --name docksal-dns --label "io.docksal.group=system" --restart=always \
		-p "$ip":53:53/udp --cap-add=NET_ADMIN --dns "$dns" \
		-e DNS_IP="$ip" -e DNS_DOMAIN="$DOCKSAL_DNS_DOMAIN" \
		-v /var/run/docker.sock:/var/run/docker.sock \
		"${IMAGE_DNS}" >/dev/null
}

# Configure system-wide *.docksal resolver using /etc/resolver
configure_resolver_mac () {
	local TARGET_IP="$1"
	if (grep "^nameserver $TARGET_IP$" /etc/resolver/$DOCKSAL_DNS_DOMAIN >/dev/null 2>&1); then
		return
	fi
	sudo mkdir -p /etc/resolver
	# deleting old resolver is the only way to get mac to update config
	sudo rm -r "/etc/resolver/$DOCKSAL_DNS_DOMAIN" >/dev/null 2>&1
	# NO \n at the beginning of line here!
	echo -e "# .$DOCKSAL_DNS_DOMAIN domain resolution\nnameserver $TARGET_IP" | \
		sudo tee 1>/dev/null "/etc/resolver/$DOCKSAL_DNS_DOMAIN"
	sudo dscacheutil -flushcache
	# to check: scutil --dns
}

# Configure system-wide *.docksal resolver using custom subnet and dns-nameservers instruction
configure_resolver_linux () {
	# Adding a subnet for Docksal. Make sure we don't do this twice
	if ! grep -q "$DOCKSAL_DEFAULT_SUBNET" /etc/network/interfaces; then
		echo-green "Adding a subnet for Docksal..."
		cat > /tmp/docksal.ip.addr <<EOF
	up   ip addr add ${DOCKSAL_DEFAULT_SUBNET} dev lo label lo:docksal
	down ip addr del ${DOCKSAL_DEFAULT_SUBNET} dev lo label lo:docksal
	dns-nameservers ${DOCKSAL_DEFAULT_IP}
EOF
		sudo sed -i '/iface lo inet loopback/r /tmp/docksal.ip.addr' /etc/network/interfaces
		rm -f /tmp/docksal.ip.addr
		sudo ifdown --force lo 2>/dev/null
		sudo ifup lo
		sudo resolvconf -u
	fi
}

# Configure system-wide *.docksal resolver
configure_resolver_windows () {
	return
}

# Configure system-wide *.docksal resolver (Windows is not supported)
configure_resolver ()
{
	check_docker_running
	local TARGET_IP="$DOCKSAL_DEFAULT_IP"

	if is_mac; then
		is_docker_native && TARGET_IP="127.0.0.1"
		install_dns_service "$TARGET_IP"
		configure_resolver_mac "$TARGET_IP"

	elif is_linux; then
		install_dns_service "$DOCKSAL_DEFAULT_IP"
		configure_resolver_linux

	elif is_windows; then
		is_docker_native && TARGET_IP="127.0.0.1"
		install_dns_service "$TARGET_IP"
		configure_resolver_windows "$TARGET_IP" # maybe someday
	fi
}

install_sshagent_service ()
{
	docker rm -f docksal-ssh-agent >/dev/null 2>&1 || true
	docker volume rm docksal_ssh_agent >/dev/null 2>&1 || true

	docker volume create --name docksal_ssh_agent >/dev/null 2>&1
	docker run -d --name docksal-ssh-agent --label "io.docksal.group=system" --restart=always \
		-v docksal_ssh_agent:/.ssh-agent \
		-v /var/run/docker.sock:/var/run/docker.sock \
		"${IMAGE_SSH_AGENT}" >/dev/null
	# Add default keys. Using || true here to suppress errors if there are not keys on the host.
	fin ssh-add || true
}

# Install tools on Mac
install_tools_mac ()
{
	if ! is_docker_native; then
		# Check VirtualBox
		check_vbox_version
	fi

	mkdir -p "$CONFIG_DOWNLOADS_DIR" 2>/dev/null
	if_failed "Could not create $CONFIG_DOWNLOADS_DIR"

	# Install Docker client
	if ! is_docker_version; then
		local docker_pkg=$(basename "$URL_DOCKER_MAC")
		echo-green "Installing docker client v${REQUIREMENTS_DOCKER}..."
		if [[ ! -f "$docker_pkg" ]]; then
			echo-green "Downloading ${docker_pkg}..."
			curl -fL# "$URL_DOCKER_MAC" -o "$CONFIG_DOWNLOADS_DIR/$docker_pkg"
			if_failed "Check internet connection."
		# Use a local/portable copy if available
		else
			echo "Found a local copy of ${docker_pkg}. Using it..."
			cp -f "$docker_pkg" "$CONFIG_DOWNLOADS_DIR"
			if_failed "Check file permissions."
		fi

		# Run in sub-shell so we don't have to cd back
		(
			cd "$CONFIG_DOWNLOADS_DIR" && \
			tar zxf "$docker_pkg" && \
			mv "docker/docker" "$CONFIG_BIN_DIR/" && \
			chmod +x "$DOCKER_BIN"
		)
		if_failed "Check file permissions."
	fi

	# Install docker-compose
	if ! is_docker_compose_version; then
		local dc_pkg=$(basename "$URL_DOCKER_COMPOSE_MAC")
		echo-green "Installing docker-compose v${REQUIREMENTS_DOCKER_COMPOSE}..."
		if [[ ! -f "$dc_pkg" ]]; then
			echo-green "Downloading ${dc_pkg}..."
			curl -fL# "$URL_DOCKER_COMPOSE_MAC" -o "$DOCKER_COMPOSE_BIN" && \
				chmod +x "$DOCKER_COMPOSE_BIN"
			if_failed "Check file permissions and internet connection."
		# Use a local/portable copy if available
		else
			echo "Found a local copy of ${dc_pkg}. Using it..."
			cp -f "$dc_pkg" "$DOCKER_COMPOSE_BIN" && \
				chmod +x "$DOCKER_COMPOSE_BIN"
			if_failed "Check file permissions."
		fi
	fi

	# Install docker-machine
	if ! is_docker_machine_version; then
		local dm_pkg=$(basename "$URL_DOCKER_MACHINE_MAC")
		echo-green "Installing docker-machine v${REQUIREMENTS_DOCKER_MACHINE}..."
		if [[ ! -f "$dm_pkg" ]]; then
			echo-green "Downloading ${dm_pkg}..."
			curl -fL# "$URL_DOCKER_MACHINE_MAC" -o "$DOCKER_MACHINE_BIN" && \
				chmod +x "$DOCKER_MACHINE_BIN"
			if_failed "Check file permissions and internet connection."
		# Use a local/portable copy if available
		else
			echo "Found a local copy of ${dm_pkg}. Using it..."
			cp -f "$dm_pkg" "$DOCKER_MACHINE_BIN" && \
				chmod +x "$DOCKER_MACHINE_BIN"
			if_failed "Check file permissions."
		fi
	fi

	# Cleanup
	rm -rf "$CONFIG_DOWNLOADS_DIR" >/dev/null 2>&1

	# If it was an upgrade
	[[ "$BOOT2DOCKER_NEEDS_AN_UPGRADE" == "1" ]] && \
		is_docker_machine_running && \
		echo-green "Preparing to update virtual machine..." && \
		docker_machine_stop && \
		echo "Downloading boot2docker.iso v${REQUIREMENTS_DOCKER}" && \
		curl -fL# "$URL_BOOT2DOCKER" -o "$HOME/.docker/machine/machines/$DOCKER_MACHINE_NAME/boot2docker.iso" && \
		docker_machine_start

	if is_docker_native && [[ ${UPGRADE_IN_PROGRESS} == 1 ]]; then
		local server_version=$(docker version --format '{{.Server.Version}}')
		if [[ $(ver_to_int "$REQUIREMENTS_DOCKER") > $(ver_to_int "$server_version") ]]; then
			echo-yellow "[IMPORTANT]: update Docker for Mac to the latest version manually"
			sleep 2
		fi
	fi
}

install_tools_windows ()
{
	mkdir -p "$CONFIG_DOWNLOADS_DIR" 2>/dev/null
	if_failed "Could not create $CONFIG_DOWNLOADS_DIR"

	# Disable Babun update checks as they often bring problems
	if ! (grep '^export DISABLE_CHECK_ON_STARTUP="true"' "$HOME/.babunrc" >/dev/null 2>&1); then
		echo "\n"'export DISABLE_CHECK_ON_STARTUP="true"' >> "$HOME/.babunrc"
	fi

	if ! is_docker_native; then
		# Check VirtualBox
		check_vbox_version
	fi

	# Install Docker client
	if ! is_docker_version; then
		local docker_pkg=$(basename "$URL_DOCKER_WIN")
		echo-green "Installing docker client v${REQUIREMENTS_DOCKER}..."
		if [[ ! -f "$docker_pkg" ]]; then
			echo-green "Downloading ${docker_pkg}..."
			curl -fL# "$URL_DOCKER_WIN" -o "$CONFIG_DOWNLOADS_DIR/$docker_pkg"
			if_failed "Check internet connection."
		# Use a local/portable copy if available
		else
			echo "Found a local copy of ${docker_pkg}. Using it..."
			cp -f ${docker_pkg} "$CONFIG_DOWNLOADS_DIR"
			if_failed "Check file permissions."
		fi

		# Run in sub-shell so we don't have to cd back
		(
			cd "$CONFIG_DOWNLOADS_DIR" && \
			unzip ${docker_pkg} && \
			mv "docker/docker.exe" "$DOCKER_BIN.exe" && \
			chmod +x "$DOCKER_BIN"
		)
		if_failed "Check file permissions."
	fi


	# Install docker-compose
	if ! is_docker_compose_version; then
		local dc_pkg=$(basename "$URL_DOCKER_COMPOSE_WIN")
		echo-green "Installing docker-compose v${REQUIREMENTS_DOCKER_COMPOSE}..."
		if [[ ! -f "$dc_pkg" ]]; then
			echo-green "Downloading ${dc_pkg}..."
			curl -fL# "$URL_DOCKER_COMPOSE_WIN" -o "$DOCKER_COMPOSE_BIN.exe" && \
				chmod +x "$DOCKER_COMPOSE_BIN.exe"
			if_failed "Check file permissions and internet connection."
		# Use a local/portable copy if available
		else
			echo "Found a local copy of ${dc_pkg}. Using it..."
			cp -f "$dc_pkg" "$DOCKER_COMPOSE_BIN.exe" && \
				chmod +x "$DOCKER_COMPOSE_BIN.exe"
			if_failed "Check file permissions."
		fi
	fi

	# Install docker-machine
	if ! is_docker_machine_version; then
		local dm_pkg=$(basename "$URL_DOCKER_MACHINE_WIN")
		echo-green "Installing docker-machine v${REQUIREMENTS_DOCKER_MACHINE}..."
		if [[ ! -f "$dm_pkg" ]]; then
			echo-green "Downloading ${dm_pkg}..."
			curl -fL# "$URL_DOCKER_MACHINE_WIN" -o "$DOCKER_MACHINE_BIN.exe" && \
				chmod +x "$DOCKER_MACHINE_BIN.exe"
			if_failed "Check file permissions and internet connection."
		# Use a local/portable copy if available
		else
			echo "Found a local copy of ${dm_pkg}. Using it..."
			cp -f "$dm_pkg" "$DOCKER_MACHINE_BIN.exe" && \
				chmod +x "$DOCKER_MACHINE_BIN.exe"
			if_failed "Check file permissions."
		fi
	fi

	# Install winpty
	if ! is_winpty_version; then
		echo-green "Installing winpty v${REQUIREMENTS_WINPTY}..."
		local winpty_pkg=$(basename "$URL_WINPTY")
		if [[ ! -f "$winpty_pkg" ]]; then
			echo-green "Downloading ${winpty_pkg}..."
			curl -fL# "$URL_WINPTY" -o "$CONFIG_DOWNLOADS_DIR/$winpty_pkg"
			if_failed "Check internet connection."
		# Use a local/portable copy if available
		else
			echo "Found a local copy of ${winpty_pkg}. Using it..."
			cp -f "$winpty_pkg" "$CONFIG_DOWNLOADS_DIR"
			if_failed "Check file permissions."
		fi
		# Run in sub-shell so we don't have to cd back
		(
			cd "$CONFIG_DOWNLOADS_DIR" && \
			tar zxf "$winpty_pkg" && \
			mv winpty-*/bin/* "$CONFIG_BIN_DIR/"
		)
		if_failed "Check file permissions."
	fi

	# Cleanup
	rm -rf "$CONFIG_DOWNLOADS_DIR" >/dev/null 2>&1

	# Run one-time adjustments during install only.
	if [[ ${UPGRADE_IN_PROGRESS} != 1 ]]; then
		# Optimize SMB sharing
		smb_windows_fix
		[ ! $? -eq 0 ] && echo-red "Failed. Windows shares might not work properly with Docksal."
		# Git settings
		echo-green "Adjusting git defaults..."
		echo "git config --global core.autocrlf input"
		git config --global core.autocrlf input # do not convert line breaks. treat as is
		echo "git config --system core.longpaths true"
		git config --system core.longpaths true # support long paths
	fi

	if ! is_docker_native && [[ "$BOOT2DOCKER_NEEDS_AN_UPGRADE" == "1" ]]; then
		is_docker_machine_running && \
		echo-green "Preparing to update virtual machine..." && \
		docker_machine_stop && \
		echo "Downloading boot2docker.iso v${REQUIREMENTS_DOCKER}" && \
		curl -fL# "$URL_BOOT2DOCKER" -o "$(cygpath $USERPROFILE)/.docker/machine/machines/$DOCKER_MACHINE_NAME/boot2docker.iso" && \
		docker_machine_start
	fi

	if is_docker_native && [[ ${UPGRADE_IN_PROGRESS} == 1 ]]; then
		local server_version=$(docker version --format '{{.Server.Version}}')
		if [[ $(ver_to_int "$REQUIREMENTS_DOCKER") > $(ver_to_int "$server_version") ]]; then
			echo-green-bg " [IMPORTANT]: update Docker for Windows to the latest version manually "
			sleep 2
		fi
	fi
}

# Install everything required on Ubuntu 14.04+
install_tools_ubuntu ()
{
	if ! is_tty; then
	 	echo "WARNING: Installation is running not in a tty mode"
	fi

	if ! is_ubuntu; then
		echo-red "Prerequisites installation is currently supported only on Ubuntu 14.04+"
		echo-yellow "You can continue at your own risk, if you know your Linux distribution is compatible with Ubuntu 14.04+"
		_confirm "Are you sure you want to continue?"
	fi

	# Install Docker client
	sudo service docker start 2>/dev/null
	if ! is_docker_version || ! is_docker_server_version; then
		echo-green "Installing Docker..."
		# Stop docker service if it exists
		if ps aux | grep dockerd | grep -v grep >/dev/null 2>&1; then
			echo "Stopping docker service..."
			sudo service docker stop 2>/dev/null
		fi

		# Pin docker-engine version to avoid apt-get upgrade.
		# Get rid of -ce part because linux packages use `~ce` suffix in repos and pin version will not work with it
		local PIN_DOCKER_VERSION=$(echo ${REQUIREMENTS_DOCKER} | sed "s/-.*//")
		echo -e "Package: docker-engine\nPin: version ${PIN_DOCKER_VERSION}*\nPin-Priority: 1001" | sudo tee "/etc/apt/preferences.d/docksal.pref" >/dev/null || exit 1

		curl -fsSL "${URL_DOCKER_NIX}" | \
			# patch Docker installation script on the fly to install a specific Docker version
			sed "s/apt-get install -y -q docker-engine/apt-get install -y --force-yes -q docker-engine/" | \
			sh && \
			# Using $LOGNAME, not $(whoami). See http://stackoverflow.com/a/4598126/4550880.
			sudo usermod -aG docker "$LOGNAME"
		sudo service docker start 2>/dev/null
		sudo docker version
		if_failed "Docker installation/upgrade has failed."
	fi

	# Install Docker Compose
	if ! is_docker_compose_version; then
		echo-green "Installing Docker Compose..."
		sudo curl -fL# "$URL_DOCKER_COMPOSE_NIX" -o "$DOCKER_COMPOSE_BIN_NIX" && \
			sudo chmod +x "$DOCKER_COMPOSE_BIN_NIX" && \
			docker-compose --version
		if_failed "Docker Compose installation/upgrade has failed."
	fi

	# Install docker-machine
	#	if ! is_docker_machine_version; then
	#		echo-green "Installing docker-machine v${REQUIREMENTS_DOCKER_MACHINE}..."
	#		sudo curl -sSL "$URL_DOCKER_MACHINE_NIX" -o "$DOCKER_MACHINE_BIN_NIX" && \
	#			sudo chmod +x "$DOCKER_MACHINE_BIN_NIX"
	#	fi
}

update_virtualbox () {
	local url
	local vbox_pkg

	# Preparation
	if is_windows; then
 		url="$URL_VBOX_WIN"
		vbox_pkg=$(cygpath -u "$USERPROFILE/Downloads")/$(basename "$url")
	fi

	if is_mac; then
		url="$URL_VBOX_MAC"
		vbox_pkg="$HOME/Downloads"/$(basename "$url")
	fi

	# Prefer the package found in the current directory
	if [[ -f $(basename "$url") ]]; then
		vbox_pkg="./"$(basename "$url")
	fi

	# Check again that file exists either in the current folder or in Downloads
	if [[ -f "$vbox_pkg" ]]; then
		echo "Found VirtualBox $REQUIREMENTS_VBOX in '$vbox_pkg'. Using it..."
	else
		if is_tty; then
			_confirm "Do you want to download VirtualBox $REQUIREMENTS_VBOX to '$vbox_pkg' and install it?"
		else
			echo-green "Downloading and installing VirtualBox $REQUIREMENTS_VBOX"
		fi
		# curl with download the package to the Downloads location
		curl -fL# "$url" -o "$vbox_pkg"
	fi

	# Stop VM
	fin vm stop >/dev/null 2>&1

	# Download and install Mac
	is_mac && (
		echo "Attaching ${vbox_pkg}"
		hdiutil detach "/Volumes/VirtualBox" >/dev/null 2>&1
		hdiutil attach "$vbox_pkg" -quiet &&
			open "/Volumes/VirtualBox" &&
			sleep 1 &&
			open "/Volumes/VirtualBox/VirtualBox.pkg"
	)

	# Download and install Win
	is_windows && (
		cmd /c start "$vbox_pkg"
	)

	# Wait for installation to finish
	echo
	if ! is_tty; then
		echo "Please finish VirtualBox installation using installer (Ctrl+C to exit)..."
	fi

	while ! is_vbox_version; do
		read -p "Please finish VirtualBox installation and press ENTER to continue (Ctrl+C to exit)..."
		sleep 1
	done
}

update_tools ()
{
	is_windows && \
		install_tools_windows && \
		return $?

	is_linux && \
		install_tools_ubuntu && \
		return $?

	is_mac && \
		install_tools_mac && \
		return $?
}

update_config_files ()
{
	echo-green "Updating default configs..."
	files_to_download="
			$URL_STACKS_SERVICES
			$URL_STACKS_STACK_ACQUIA
			$URL_STACKS_STACK_ACQUIA_STATIC
			$URL_STACKS_STACK_DEFAULT
			$URL_STACKS_STACK_DEFAULT_STATIC
			$URL_STACKS_VOLUMES_BIND
			$URL_STACKS_VOLUMES_NFS
			$URL_STACKS_VOLUMES_UNISON
	"
	(
		cd "$CONFIG_STACKS_DIR" || exit 1;
		# Cleanup the stacks directory before downloading files (this will help with updates, when file names are changing).
		rm -f "$CONFIG_STACKS_DIR/*"
		for f in ${files_to_download}; do
			echo "$(basename ${f})"
			# exit subshell with error if download failed
			curl -kfsSLO "$f" || exit 1
		done
	)

	if_failed_error "One of the default configs was not downloaded." \
		"Check your internet connection and file permission on $CONFIG_STACKS_DIR"
}

# Install shell commands autocomplete script
install_bash_autocomplete ()
{
	local destination="$FIN_AUTOCOMPLETE_PATH"
	tee "$destination" >/dev/null << 'EOF'
_docksal_completion()
{
	local cur=${COMP_WORDS[COMP_CWORD]} #current word part
	local prev=${COMP_WORDS[COMP_CWORD-1]} #previous word
	local compwords=$(fin bash_comp_words $prev) #get completions for previous word
	if [ ! $? -eq 0 ]; then
		return 1;
	else
		COMPREPLY=( $(compgen -W "$compwords" -- $cur) )
		return 0
	fi
}
complete -o bashdefault -o default -F _docksal_completion fin
EOF
	if_failed "Failed to write file to $destination"
	echo-green "Script saved to $destination"
	chmod +x "$destination"

	SOURCE_FILE=".bash_profile"
	grep -q "$destination" "$HOME/$SOURCE_FILE"
	if [[ $? -ne 0 ]]; then
		echo -e ". $destination" >> "$HOME/$SOURCE_FILE"
		if_failed "Failed to write file to $HOME/$SOURCE_FILE"
		echo-green "Autocomplete appended to $HOME/$SOURCE_FILE"
		echo-yellow "Please restart your bash session to apply"
	fi
}

# Update start script and shortcut
update_start_script_shortcut()
{
	rm "$BABUN_HOME/docksal.bat" >/dev/null 2>&1
	rm "$BABUN_HOME/docksal.ico" >/dev/null 2>&1
	rm "$BABUN_HOME/tools/link_icon.vbs" >/dev/null 2>&1
	curl -kfsSL "${URL_REPO}/${DOCKSAL_VERSION}/scripts/link_icon.vbs" -o "$(cygpath $BABUN_HOME)/tools/link_icon.vbs"
	curl -kfsSL "${URL_REPO}/${DOCKSAL_VERSION}/scripts/docksal.bat" -o "$(cygpath $BABUN_HOME)/docksal.bat"
	curl -kfsSL "${URL_REPO}/${DOCKSAL_VERSION}/scripts/docksal.ico" -o "$(cygpath $BABUN_HOME)/docksal.ico"
	cscript //Nologo "$BABUN_HOME\tools\link_icon.vbs" "$USERPROFILE\Desktop\Docksal.lnk" "$BABUN_HOME\docksal.bat" "$BABUN_HOME\docksal.ico"
}

# Update system service images
update_system_images ()
{
	check_docker_running

	IMAGE_FILE=${IMAGE_FILE:-docksal-system-images.tar}
	if [[ -f "$IMAGE_FILE" ]]; then
		# Load system images from the current directory when available
		echo "Found $IMAGE_FILE. Using it..."
		image_load "$IMAGE_FILE"
	else
		# Load system images as usually from Docker Hub
		docker pull "${IMAGE_VHOST_PROXY}"
		docker pull "${IMAGE_DNS}"
		docker pull "${IMAGE_SSH_AGENT}"
	fi
	reset system
}

# Update project images
update_project_images ()
{
	# Need docker-compose configuration to be properly loaded here
	load_configuration
	check_docksal_environment
	docker-compose pull # update project containers images
	up
}

# Update Docksal
update ()
{
	# Do not run full update is running from $FIN_PATH_UPDATED (self initiated sub-shell)
	[[ "$0" == "$FIN_PATH_UPDATED" ]] && FULL_UPDATE="exit 1"

	# Pre-update check #1: check if there is existing but stopped Docksal machine
	# We need it running to know Docker server version
	if (${FULL_UPDATE}); then
		if ! is_linux && ! is_docker_native && which 'docker-machine' >/dev/null 2>&1; then
			if is_docker_machine_exist && ! is_docker_machine_running; then
				echo-error "Docker Machine '$DOCKER_MACHINE_NAME' should be running to perform update" \
					"Start it with ${yellow}fin vm start${NC} or destroy it with ${yellow}fin vm remove${NC} if you want it re-created."
				return 1
			fi
		fi
	fi

	# Checking docker status
	if (which 'docker' >/dev/null 2>&1); then
		is_docker_running
		RUNNING_CODE=$? # cache status
		if (exit ${RUNNING_CODE}); then
			# If docker is already running, then we are doing an upgrade.
			UPGRADE_IN_PROGRESS=1
		else
			# Check out the case when current user on linux does not have access to docker daemon
			if is_linux; then
				ps -p $(cat /var/run/docker.pid) 2>&1 >/dev/null
				[ ! $? -eq 0 ] && LINUX_DAEMON_RUNNING="exit 1"
				# if daemon is running but docker info does not return 0 then this is the case
				if (${LINUX_DAEMON_RUNNING}) && ! (exit ${RUNNING_CODE}); then
					echo-red "Your Docker daemon is running but you don't have access to it."
					echo-yellow "Please run 'newgrp docker' or reboot."
					exit 1
				fi
			fi
		fi
	fi

	# Pre-update check #2: warn if boot2docker will need to be upgraded
	if (is_mac || is_windows) && ! is_docker_native && [[ ${UPGRADE_IN_PROGRESS} == 1 ]]; then
		local b2d_version=$(docker version --format '{{.Server.Version}}')
		if [[ $(ver_to_int "$REQUIREMENTS_DOCKER") > $(ver_to_int "$b2d_version") ]]; then
			BOOT2DOCKER_NEEDS_AN_UPGRADE=1
			(${FULL_UPDATE}) &&
				_confirm "All running projects will be stopped for vm upgrade. Continue?"
		fi
	fi

	# [Update - 1] Update fin unless already running fin.updated binary
	if (${FULL_UPDATE}); then
		testing_warn
		echo-green "Updating fin..."
		local new_fin
		new_fin=$(curl -kfsSL "$URL_FIN?r=$RANDOM")
		if_failed_error "fin download failed."

		# Check if fin update is required and whether it is a major version
		local new_version=$(echo "$new_fin" | grep "^FIN_VERSION=" | cut -f 2 -d "=")

		if [[ "$new_version" != "$FIN_VERSION" ]]; then
			local current_major_version=$(echo "$FIN_VERSION" | cut -d "." -f 1)
			local new_major_version=$(echo "$new_version" | cut -d "." -f 1)
			if [[ "$current_major_version" != "$new_major_version" ]]; then
				echo -e "${red_bg} WARNING ${NC} ${red}Non-backwards compatible version update${NC}"
				echo -e "Updating from ${yellow}$FIN_VERSION${NC} to ${yellow}$new_version${NC} is not backward compatible."
				echo "You may not be able to use you current Docksal environment if you proceed."
				echo -e "Please read update documentation: ${yellow}$URL_REPO_UI#updates${NC}"
				_confirm "Continue with the update?"
			fi

			# saving to file
			echo "$new_fin" | sudo tee "$FIN_PATH_UPDATED" > /dev/null
			if_failed_error "Could not write $FIN_PATH_UPDATED"
			sudo chmod +x "$FIN_PATH_UPDATED"
			local new_version=$(${FIN_PATH_UPDATED} v)
			echo "fin $new_version downloaded..."

			# Run other Updates 2-5 with newly downloaded fin version
			( "$FIN_PATH_UPDATED" update )

			# overwrite old fin
			sudo mv "$FIN_PATH_UPDATED" "$FIN_PATH"
			exit
		else
			echo-rewrite "Updating fin... $FIN_VERSION ${green}[OK]${NC}"
		fi
	fi

	# [Update - 2] Update default configs
	update_config_files

	# [Update - 3] Update start script and shortcut
	if is_windows; then
		echo-green "Updating start script and shortcut..."
		update_start_script_shortcut
	fi

	# [Update - 4] Update third party tools
	update_tools

	# [Update - 5] Update system images

	# Always update system images during upgrade
	if [[ ${UPGRADE_IN_PROGRESS} == 1 ]]; then
		echo-green "Updating system images..."
		update_system_images
		# Run cleanup to get rid of outdated images
		cleanup
	fi

	# On Linux also do it during install, but use sudo as user will not be in docker group yet.
	# On Win and Mac it is done in docker_machine_start
	if [[ ${UPGRADE_IN_PROGRESS} != 1 ]] && is_linux; then
		# On Linux a subnet needs to be created first
		configure_resolver_linux
		echo-green "Updating system images..."
		# Override docker to run it via sudo
		docker () {
			sudo "$(which docker)" "$@"
		}
		update_system_images
	fi

	# [Update - 6] Restart running projects if BOOT2DOCKER was not restarted
	# This is needed to re-append restarted vhost-proxy to containers networks
	if [[ ${UPGRADE_IN_PROGRESS} == 1 ]] && [[ "$BOOT2DOCKER_NEEDS_AN_UPGRADE" != "1" ]]; then
		echo-green "Restarting running projects..."
		running_projects=$(docker ps --all \
			--filter 'status=running' \
			--filter 'label=com.docker.compose.service=web' \
			--format '{{.Label "io.docksal.project-root"}}'
		)
		for project in ${running_projects}; do
			# use updated version when updated
			[[ ! -f "$FIN_PATH_UPDATED" ]] && FIN_PATH_UPDATED="fin"
			(cd "$project" && NO_UPDATES=1 "$FIN_PATH_UPDATED" start)
		done
	fi

	[ $? -eq 0 ] && echo-green "Update finished"

	if is_linux && [[ ${UPGRADE_IN_PROGRESS} != 1 ]]; then
		echo -e "${yellow}IMPORTANT NOTE FOR LINUX USERS:${NC}"
		echo -e "  Current user was added to the 'docker' group."
		echo -e "  Re-login or run ${yellow}newgrp docker${NC} now to apply that change and use Docksal."
	fi
}

check_for_updates ()
{
	# Never trigger in scripts
	if ! is_tty; then return; fi
	local UPDATE_AVAILABLE=0
	local UPDATES_AVAILABLE=0

	local timestamp; local last_check; local next_check; local last_ping; local next_ping
	local one_day=$((60*60*24))
	local one_week=$(($one_day * 7))
	timestamp=$(date +%s)
	# Set last_check/last_ping to 0 if empty
	last_check=$(cat "$CONFIG_LAST_CHECK" 2>/dev/null || echo 0)
	last_ping=$(cat "$CONFIG_LAST_PING" 2>/dev/null || echo 0)

	# Send ping daily
	next_ping=$(( $last_ping + $one_day ))
	if [ ${timestamp} -gt ${next_ping} ]; then
		stats_ping
		echo "$timestamp" > "$CONFIG_LAST_PING"
	fi

	# Check once bi-weekly
	next_check=$(( $last_check + ($one_week * 2) ))
	if [ ${timestamp} -le ${next_check} ]; then
		return;
	fi

	echo 'One second! Checking for updates...'
	local new_fin; local new_version
	# Always write current timestamp to last check file
	echo "$timestamp" > "$CONFIG_LAST_CHECK"
	# No -S for curl here to be completely silent. Connection timeout 1 sec, total max time 3 sec or fail
	new_fin=$(curl -kfsL --connect-timeout 1 --max-time 3 "$URL_FIN?r=$RANDOM")
	new_version=$(echo "$new_fin" | grep "^FIN_VERSION=" | cut -f 2 -d "=")
	if [[ $(ver_to_int "$new_version") > $(ver_to_int ${FIN_VERSION}) ]]; then
		UPDATE_AVAILABLE=1
		echo-green-bg " UPDATE AVAILABLE "
		echo -e "${green}fin${NC} [ $FIN_VERSION --> $new_version ]"
		echo "Press Enter to continue"
		read -p ''
	fi
}

# Export docker images from the host into a tar archive
# @param $1 mode: --system, --project, --all
image_save ()
{
	local mode="$1"; shift
	if [[ "$mode" == "--system" ]]; then
		echo "Saving system images..."
		docker ps --filter "label=io.docksal.group=system" --format "{{.Image}}" | xargs docker save -o docksal-system-images.tar
	elif [[ "$mode" == "--project" ]]; then
		load_configuration
		echo "Saving ${COMPOSE_PROJECT_NAME} project images..."
		docker-compose config | grep image | sed 's/.*image: \(.*\)/\1/' | xargs docker save -o docksal-${COMPOSE_PROJECT_NAME}-images.tar
	elif [[ "$mode" == "--all" ]]; then
		echo "Saving all images available on the host..."
		docker image ls -q | xargs docker save -o docksal-all-images.tar
	else
		echo "Usage: save <mode> (--system, --project, --all)"
	fi
}

# Import docker images from a tar archive
# @param $1 file
image_load ()
{
	local file="$1"; shift
	docker load -i "$file"
}

image_registry_list ()
{
	if [[ "$1" != "" ]]; then
		echo "$1 tags"
		echo "----------"
		# for instance $1 == "docksal/db"
		curl -ksSL https://registry.hub.docker.com/v2/repositories/${1}/tags | grep -o 'name\":\ \"[-_\.a-zA-Z0-9]*' | cut -d " " -f2 | tr -d \"
	else
		fin docker search "docksal" | grep "^docksal\/"
	fi
}

#-------------------------- Execution commands -----------------------------

# Start an interactive bash session in a container
# @param $1 container name
_bash ()
{
	check_docker_running
	# Interactive shell requires a tty.
	# On Windows we assume we run interactively via winpty.
	if ! is_tty; then
		echo "not a tty"
		return 1
	fi

	# Pass container name to _run
	CONTAINER_NAME=$1 _exec bash -i
}

# Run a command in the cli container changing dir to the same folder
# @param $* command with its params to run
_exec ()
{
	[[ $1 == "" ]] && \
		show_help_exec && exit
	check_docksal_environment
	check_winpty_found

	# Allow disabling TTY mode.
	# Useful for non-interactive commands when output is saved into a variable for further comparison.
	# In a TTY mode the output may contain unexpected control symbols/etc.
	[[ $1 == "-T" ]] && \
		local no_tty=true && shift

	# CONTAINER_NAME can be used to override where to run. Used in _bash()
	CONTAINER_NAME=${CONTAINER_NAME:-cli}
	container_id=$(get_container_id "$CONTAINER_NAME")

	# ------------------------------------------------ #
	# 1) cmd
	local cmd

	local cdir
	# Only chdir to the same dir in cli container
	# RUN_NO_CDIR can be used to override this (used in mysql_import)
	if [[ "$CONTAINER_NAME" == "cli" ]] && [[ "$RUN_NO_CDIR" != 1 ]]; then
		local path=$(get_current_relative_path)
		if [[ "$path" != "" ]] ; then
			# We are deeper than project root and thus need to do a cd
			cdir="cd $path &&"
		fi
	fi

	cmd="$cdir"
	# ------------------------------------------------ #

	# ------------------------------------------------ #
	# 2) convert array of parameters into escaped string
	# Escape spaces that are "spaces" and not parameter delimeters (i.e. param1 param2\ with\ spaces param3)
	if [[ $2 != "" ]]; then
		cmd="$cmd "$(printf " %q" "$@")
	# Do not escape spaces if there is only one parameter (e.g. fin run "ls -la | grep txt")
	else
		cmd="$cmd $@"
	fi
	# ------------------------------------------------ #

	# ------------------------------------------------ #
	# 3) execute
	# Allow entering arbitrary containers by name (e.g. system containers like vhost-proxy).
	if [[ "$container_id" == "" ]]; then
		${winpty} docker exec -it "$CONTAINER_NAME" sh -i
		return
	fi

	if [[ "$CONTAINER_NAME" == "cli" ]]; then
		# Source $HOME/.docksalrc in cli.
		# Commands in this file will be sourced for both interactive and non-interactive sessions.
		local DOCKSALRC='source $HOME/.docksalrc >/dev/null 2>&1;'
		# Commands in cli should be run using the docker user, not root.
		local container_user='-u docker'
	fi

	# Enter project containers
	# Use the docker user in cli (-u docker) instead of root (default user).
	if is_tty && [[ "$no_tty" != true ]]; then
		# interactive
		# (exit \$?) is a hack to return correct exit codes when docker exec is run with tty (-t).
		${winpty} docker exec -it $container_user "$container_id" bash -ic "$DOCKSALRC $cmd; (exit \$?)"
	else
		# non-interactive
		docker exec $container_user "$container_id" bash -c "$DOCKSALRC $cmd"
	fi
	# ------------------------------------------------ #
}

# Run a command in a standalone cli container (outside of any project).
# The current directory on the host is mapped to /var/www inside the container.
# @param $* command with its params to run.
run_cli ()
{
	# Allow disabling TTY mode.
	# Useful for non-interactive commands when output is saved into a variable for further comparison.
	# In a TTY mode the output may contain unexpected control symbols/etc.
	[[ $1 == "-T" ]] && \
		local no_tty=true && shift
	# Set default image
	local IMAGE="${IMAGE:-docksal/cli:1.2-php7}"
	local cmd="$@"

	# Source $HOME/.docksalrc in cli.
	# Commands in this file will be sourced for both interactive and non-interactive sessions.
	DOCKSALRC='source $HOME/.docksalrc >/dev/null 2>&1'

	# Debug mode off by default
	DEBUG=${DEBUG:-0}

	if is_tty && [[ "$no_tty" != true ]]; then

		# interactive
		# (exit \$?) is a hack to return correct exit codes when docker exec is run with tty (-t).
		
		${winpty} docker run --rm -it -v $(pwd):/var/www -e HOST_UID=$(id -u) -e HOST_GID=$(id -g) -e DEBUG="$DEBUG" ${IMAGE} bash -ic "$DOCKSALRC; $cmd; (exit \$?)"
	else
		# non-interactive

		docker run --rm -v $(pwd):/var/www -e HOST_UID=$(id -u) -e HOST_GID=$(id -g) -e DEBUG="$DEBUG" ${IMAGE} bash -c "$DOCKSALRC; $cmd"
	fi
}

# Start interactive mysql shell
# --db-user="admin" to override mysql username
# --db-password="otherpass" to override mysql password
mysql ()
{
	check_winpty_found
	eval $(parse_params "$@")

	local __dump_user="${dbuser:-root}"
	local __dump_password="${dbpassword:-\$MYSQL_ROOT_PASSWORD}"

	check_docksal_environment
	container_id=$(get_container_id "db")
	__mysql_command=$(docker exec "$container_id" bash -c "echo -u$__dump_user -p$__dump_password")
	${winpty} docker exec -it "$container_id" mysql ${__mysql_command}
}

# Show databases list
# --db-user="admin" to override mysql username
# --db-password="otherpass" to override mysql password
mysql_list ()
{
	check_docksal_environment
	eval $(parse_params "$@")

	local __dump_user="${dbuser:-root}"
	local __dump_password="${dbpassword:-\$MYSQL_ROOT_PASSWORD}"

	# -N parameter suppresses columns header
	_RUN_NO_CDIR=1 CONTAINER_NAME="db" \
		_exec "echo 'show databases' | mysql -N -u $__dump_user -p${__dump_password}"
}

# Truncate db and import from sql dump
# @params
# $1 - file name
# --db="drupal" to override database username
# --db-user="admin" to override mysql username
# --db-password="otherpass" to override mysql password
mysql_import ()
{
	check_docksal_environment
	eval $(parse_params "$@")

	local __dump_user="${dbuser:-root}"
	local __dump_password="${dbpassword:-\$MYSQL_ROOT_PASSWORD}"
	local __database="${db:-default}"
	# /dev/fd/0 is the stdin stream for current script
	# IMPORTANT: don't run "docker exec" with "-i" until value of /dev/fd/0 is used or it's value will be lost
	local __input="${ARGV[0]:-/dev/fd/0}"

	[[ "$__input" != "/dev/fd/0" ]] && [[ ! -r "$__input" ]] &&
		echo-error "Can not read $__input" "Please check file path and permissions" && exit 1

	local confirm=0
	if [[ "$force" == "force" ]]; then
		confirm=1
	fi

	#-- 1) TRUNCATING
	echo "Truncating '$__database'..."
	# next line should go in one line to be treated as a single command by _run and have pipe being run on container side
	local TRUNCATE_DATABASE_COMMAND="mysqldump -u$__dump_user -p$__dump_password --add-drop-table --no-data $__database | grep -e '^DROP \| FOREIGN_KEY_CHECKS' | mysql -u$__dump_user -p$__dump_password $__database"

	_RUN_NO_CDIR=1 CONTAINER_NAME="db" \
		_exec "${TRUNCATE_DATABASE_COMMAND}"

	if [[ ! $? -eq 0 ]] && (exit ${confirm}); then
		_confirm "There were errors during truncation. Continue anyways?"
	else
		echo-rewrite-ok "Truncating '$__database'..."
	fi

	#-- 2) IMPORTING
	echo "Importing..."
	# We can not use _run here because we need to launch docker exec with only -i param
	# and only mysql command direclty (no bash wrapper) so that stdin could be received inside that exec
	container_id=$(get_container_id "db")
	__mysql_command=$(docker exec "$container_id" bash -c "echo -u$__dump_user -p$__dump_password")
	__mysql_command=$(echo "$__mysql_command" | sed -e 's/[^a-zA-Z0-9_-]$//')
	# "docker exec -i" is required as it creates stdin/stdout streams but does not create tty
	cat ${__input} | docker exec -i ${container_id} mysql ${__mysql_command} ${__database}

	# Check if import succeded or not and print results.
	if [ $? -eq 0 ]; then
		echo-rewrite-ok "Importing..."
		exit 0
	else
		echo-red "Import failed";
		exit 1
	fi
}

# Dump mysql database
# @params
# $1 - file name, if ommitted then stdout
# --db="drupal" to override database username
# --db-user="admin" to override mysql username
# --db-password="otherpass" to override mysql password
mysql_dump ()
{
	check_docksal_environment
	eval $(parse_params "$@")

	local __dump_user="${dbuser:-root}"
	local __dump_password="${dbpassword:-\$MYSQL_ROOT_PASSWORD}"
	local __database="${db:-default}"
	local __output="${ARGV[0]}"

	if [[ "${ARGV[0]}" != "" ]]; then
		touch "$__output"
		if_failed_error "Could not write $__output" "Please check your file permissions"
		echo-green "Exporting..."
	fi

	container_id=$(get_container_id "db")
	__mysql_command=$(docker exec -i "$container_id" bash -c "echo -u$__dump_user -p$__dump_password")
	if [[ "${ARGV[0]}" == "" ]]; then
		docker exec -i "$container_id" mysqldump ${__mysql_command} ${__database}
	else
		docker exec -i "$container_id" mysqldump ${__mysql_command} ${__database} | tee "$__output" >/dev/null
	fi

	if [[ "${ARGV[0]}" != "" ]]; then
		[ $? -eq 0 ] && echo-rewrite-ok "Exporting..."
	fi
}

# Download script by URL and execute it
# @param $1 url of script.
exec_url ()
{
	if [[ "$1" != "" ]]; then
		_confirm "Run script from '$1'?"
		local script
		script=$(curl -kfsSL "$1")
		if_failed "Failed downloading script $1"
		shift
		(eval "${script}")
	else
		show_help_exec-url
	fi
}

# Reset container(s) (stop, remove, up)
# @param $1 $2... containers names
reset ()
{
	check_docker_running

	if [[ "$1" == "proxy" ]] ; then
		echo-green 'Resetting Docksal HTTP/HTTPS reverse proxy service...'
		install_proxy_service
		return
	fi

	if [[ "$1" == "dns" ]] ; then
		echo-green 'Resetting Docksal DNS service and configuring resolver for .docksal domain...'
		configure_resolver
		return
	fi

	if [[ "$1" == "ssh-agent" ]] ; then
		echo-green 'Resetting Docksal ssh-agent service...'
		install_sshagent_service
		return
	fi

	if [[ "$1" == "system" ]] ; then
		echo-green 'Resetting Docksal services...'
		echo ' * proxy'
		install_proxy_service
		echo ' * dns and resolver for .docksal domain'
		configure_resolver
		echo ' * ssh-agent'
		install_sshagent_service
		return
	fi

	check_docksal
	# support quiet removal
	if [[ $1 == "-f" ]]; then
		shift
		remove -f "$@"
	else
		remove "$@"
	fi
	_start_containers
}

# Show logs
# @param $* container(s) name
logs ()
{
	check_docker_running
	docker-compose logs "$@"
}

# TODO: remove in September 2017, as this functionality was ported inside docksal/cli
# Set uid of the primary "docker" user in the cli container
# Useful to match the host uid with the uid in the cli container and avoid file permission issues this way.
_set_cli_uid ()
{
	# Let uid to be set with the FIN_SET_UID env variable
	local host_uid=${FIN_SET_UID:-$(id -u)}
	local host_gid=${FIN_SET_GID:-$(id -g)}
	local cli=$(get_container_id cli || true)

	# If there is no cli, move on.
	if [[ -z ${cli} ]]; then
		echo-yellow 'Expected service "cli" is missing.'
		return;
	fi

	local container_uid
	# Get both uid and gid in one shot to save time
	container_uid_gid=$(docker exec -u docker ${cli} bash -c 'echo -n $(id -u):$(id -g)')
	if [[ ! $? -eq 0 ]]; then
		echo-red 'Error getting uid from cli container'
		echo "You might need to recreate containers with fin reset"
		return
	fi

	if [[ "$container_uid_gid" == "$host_uid:$host_gid" ]]; then
		return
	fi

	# TODO: output a note to the user about updating their custom yml configuration (point to the docs).
	if [[ "$host_uid" != "0" ]] ; then
		echo-green "Changing uid/gid in cli to $host_uid/$host_gid to match the host"
	else
		echo -e "${green}Changing user id in cli to 0 to match host user id ${NC}${yellow}(running as root is not recommended)...${NC}"
	fi
	docker exec -u root ${cli} usermod -u "$host_uid" -o docker >/dev/null 2>&1
	docker exec -u root ${cli} groupmod -g "$host_gid" -o users >/dev/null 2>&1
	# TODO: remove once confirmed this is no longer necessary
	echo-green "Resetting permissions on /var/www..."
	docker exec -u root ${cli} chown -R -h $host_uid:$host_gid /var/www

	echo-green "Restarting php daemon..."
	docker exec -u root ${cli} supervisorctl restart php-fpm >/dev/null
}

# Share web container using ngrok service
ngrok_share ()
{
	check_docksal_environment
	check_winpty_found

	local network="${COMPOSE_PROJECT_NAME_SAFE}_default"
	local container_name=$(docker-compose ps web | grep Up | grep _web_ | cut -d " " -f 1)
	if [[ "$container_name" == "" ]]; then
		echo-error "Could not find running web container in this project"
		exit 1
	fi
	local ngrok_container_name=${container_name}_ngrok

	if ( fin docker ps --format '{{.Names}}' | grep ^${ngrok_container_name}$ >/dev/null ); then
		docker stop ${ngrok_container_name} >/dev/null
		docker rm ${ngrok_container_name} >/dev/null 2>/dev/null
	fi

	# Based on https://github.com/wernight/docker-ngrok
	${winpty} docker run --rm -it \
		--net ${network} \
		--link ${container_name} \
		--name ${ngrok_container_name} \
		wernight/ngrok \
		ngrok http -host-header ${VIRTUAL_HOST} ${container_name}.${network}:80
}

sysinfo ()
{
	# os
	echo "███  OS & BASICS"
	uname -a
	# OS version
	is_linux && echo $(lsb_release -si) $(lsb_release -sr)
	is_mac && echo $(sw_vers -productName) $(sw_vers -productVersion)
	is_windows && echo $(cmd /c ver)
	# fin version
	version

	# Native vs VM
	echo "Mode: " $( ([[ "$DOCKER_NATIVE" == "1" ]] || is_linux) && echo "Native / Docker for Mac/Windows" || echo "VirtualBox VM" )

	(which 'docker-machine' >/dev/null 2>&1) && \
		echo "███  INSTANCES" && \
		docker-machine ls

	echo "███  DOCKER"
	echo "DOCKER_HOST:	$DOCKER_HOST"
	echo
	echo "Docker: $(docker version)"

	echo "███  DOCKER COMPOSE"
	echo "Docker Compose: $(docker-compose version)"

	(which 'docker-machine' >/dev/null 2>&1) && \
		echo "███  DOCKER MACHINE" && \
		docker-machine --version

	if is_docker_running; then
		echo "███  DOCKER: IMAGES"
		docker images

		echo "███  DOCKER: CONTAINERS"
		docker ps
	fi

	if which "$vboxmanage" >/dev/null 2>&1; then
		echo "███  VIRTUALBOX"
		"$vboxmanage" --version

		echo "███  NETWORK INTERFACES"
		"$vboxmanage" list hostonlyifs
	fi

	if is_mac; then
		echo "███  NFS EXPORTS"
		cat /etc/exports
	fi

	if is_docker_machine_running; then
		echo "███  MOUNTS"
		vm ssh mount
	fi

	# Ping stats server
	stats_ping
}

#-------------------------- Links / Aliases -----------------------------

# param $1 path
# param $2 alias name
alias_create ()
{
	[[ $# != 2 ]] && echo 'Usage: fin alias <path> <alias_name>' && exit 1
	mkdir -p "$CONFIG_ALIASES" || exit 1
	[[ -h "$2" ]] && echo "Alias $2 already exists" && exit 1
	[[ -e "$2" ]] && echo "Filename is not available" && exit 1
	[[ ! -d "$1" ]] && echo 'Path should be a valid dir' && exit 1

	! is_windows && \
		ln -s $(get_abs_path "$1") "$CONFIG_ALIASES/$2"

	[[ $? -eq 0 ]] && \
		echo "$2 -> $(get_abs_path $1)"
}

alias_remove () {
	[[ ! -h "$CONFIG_ALIASES/$1" ]] && echo 'Alias not found' && exit
	[[ -h "$CONFIG_ALIASES/$1" ]] && rm "$CONFIG_ALIASES/$1"
}

alias_list ()
{
	local list=$(ls -l "$CONFIG_ALIASES" 2>/dev/null | grep -v total | awk '{printf "%-19s %s\n", $9, $11}')
	[[ "$list" == "" ]] && echo "No aliases found" && exit
	printf "%-19s %s\n" "NAME" "TARGET DIR"
	echo "$list"
}


#------------------------ Project configuration and variables ---------------------------

load_configuration ()
{
	# Mac and Linux use ":"" as a separator, Windows uses ";"
	local SEPARATOR=':'; is_windows && SEPARATOR=';'
	local env_file="$(get_project_path_dc)/.docksal/docksal.env"
	local local_env_file="$(get_project_path_dc)/.docksal/docksal-local.env"
	if [[ -f "$env_file" ]]; then
		ENV_FILE="$env_file"
		fix_crlf_warning "$env_file"
		# Source and allexport variables in the .env file
		set -a; source "$env_file"; set +a
	fi

	# Source local env file if it exist
	# Allow using this with the pre-configured stacks by not checking docksal.env presence.
	if [[ -f "$local_env_file" ]]; then
			ENV_FILE="${ENV_FILE}${SEPARATOR}${local_env_file}"
			fix_crlf_warning "$local_env_file"
			# Source and allexport variables in the .env file
			set -a; source "$local_env_file"; set +a
	fi
	export ENV_FILE

	# Set COMPOSE_FILE unless it has been already set by user
	if [[ "$COMPOSE_FILE" == "" ]]; then
		yml_file="$(get_project_path_dc)/.docksal/docksal.yml"

		# Allow to define the stack file via DOCKSAL_STACK
		# Set it to "default" if empty and there is no project yml file
		[[ "$DOCKSAL_STACK" == "" ]] && [[ ! -f "$yml_file" ]] && DOCKSAL_STACK='default'
		stack_yml_file="$(get_config_dir_dc)/stacks/stack-$DOCKSAL_STACK.yml"

		# Include both the stack and the project yml files if both exist
		if [[ -f "$stack_yml_file" ]] && [[ -f "$yml_file" ]]; then
			COMPOSE_FILE="${stack_yml_file}${SEPARATOR}${yml_file}"
		# Otherwise try including only one that exists
		else
			[[ -f "$stack_yml_file" ]] && COMPOSE_FILE="$stack_yml_file"
			[[ -f "$yml_file" ]] && COMPOSE_FILE="$yml_file"
		fi

		# Throw an error if COMPOSE_FILE is empty here
		if [[ "$COMPOSE_FILE" == "" ]]; then
			echo-error "No configuration files found." "Expected in $yml_file"
			exit 1
		else
			# Include docksal-local.yml (if exists)
			# Allow using this with the pre-configured stacks by not checking docksal.env presence.
			local_yml_file="$(get_project_path_dc)/.docksal/docksal-local.yml"
			[[ -f "$local_yml_file" ]] && COMPOSE_FILE="${COMPOSE_FILE}${SEPARATOR}${local_yml_file}"
		fi

		# Include a volumes yml if requested. Use bind mount for volumes by default.
		DOCKSAL_VOLUMES=${DOCKSAL_VOLUMES:-bind}
		if [[ "$DOCKSAL_VOLUMES" != "disable" ]]; then
			volumes_yml_file="$(get_config_dir_dc)/stacks/volumes-$DOCKSAL_VOLUMES.yml"
			if [[ -f "$volumes_yml_file" ]]; then
				COMPOSE_FILE="${volumes_yml_file}${SEPARATOR}${COMPOSE_FILE}"
			else
				echo-error "Volumes definition not found in ${volumes_yml_file}." \
					"Please check that ${yellow}DOCKSAL_VOLUMES${NC} is set properly." \
					"You may need to run ${yellow}fin update${NC} to download volume definitions."
				exit 1
			fi
		fi
	fi
	export COMPOSE_FILE

	# Set project name if it was not set previously
	if [[ -d $(get_project_path) ]]; then
		local project_name=$(basename $(get_project_path) | tr '[:upper:]' '[:lower:]')
		COMPOSE_PROJECT_NAME=${COMPOSE_PROJECT_NAME:-$project_name}
		COMPOSE_PROJECT_NAME_SAFE=$(echo ${COMPOSE_PROJECT_NAME} | sed 's/[^a-z0-9]//g')
		export COMPOSE_PROJECT_NAME
		export COMPOSE_PROJECT_NAME_SAFE
	fi

	# Set defaults
	export VIRTUAL_HOST=${VIRTUAL_HOST:-$COMPOSE_PROJECT_NAME_SAFE.docksal}
	export DOCROOT=${DOCROOT:-docroot}
	export DOCKSAL_IP=${DOCKSAL_DEFAULT_IP}

	# DNS servers for containers
	# Internal name resolution (for *.docksal domains)
	export DOCKSAL_DNS1=${DOCKSAL_DEFAULT_IP}
	# External name resolution (everything else)
	if ! is_linux; then
		export DOCKSAL_DNS2=${DOCKSAL_DEFAULT_DNS}
	else
		export DOCKSAL_DNS2=${DOCKSAL_DEFAULT_DNS_NIX}
	fi

	# Make project root globally available
	export DOCKSAL_PATH="$(get_project_path)"
	export PROJECT_ROOT="$(get_project_path)"
	is_windows && export PROJECT_ROOT_WIN="$(get_project_path_dc)"
	# Set this to 0 to account for docker-compose bug https://github.com/docker/compose/pull/4294
	export COMPOSE_CONVERT_WINDOWS_PATHS=0

	# Export host user uid/gid
	export HOST_UID=$(id -u)
	export HOST_GID=$(id -g)

	if is_docker_running; then
		export DOCKER_RUNNING="true"
	else
		export DOCKER_RUNNING="false"
	fi
}

config_show ()
{
	check_docksal_environment

	echo "---------------------"
	# echo "COMPOSE_PROJECT_NAME: ${COMPOSE_PROJECT_NAME}"
	echo "COMPOSE_PROJECT_NAME_SAFE: ${COMPOSE_PROJECT_NAME_SAFE}"
	# Replace separators with new lines
	local SEPARATOR=':'; is_windows && SEPARATOR=';'
	echo -e "COMPOSE_FILE:\n$(echo ${COMPOSE_FILE} | tr ${SEPARATOR} '\n')"
	[[ "$ENV_FILE" != "" ]] &&
		echo -e "ENV_FILE:\n$(echo ${ENV_FILE} | tr ${SEPARATOR} '\n')"
	echo
	echo "PROJECT_ROOT: ${PROJECT_ROOT}"
	echo "DOCROOT: ${DOCROOT}"
	echo "VIRTUAL_HOST: ${VIRTUAL_HOST}"
	echo "VIRTUAL_HOST_ALIASES: *.${VIRTUAL_HOST}"

	local IP;
	(is_mac || is_windows) && [[ "$DOCKER_NATIVE" != 1 ]] && IP="$DOCKSAL_DEFAULT_IP"
	(is_mac || is_windows) && [[ "$DOCKER_NATIVE" == 1 ]] && IP="127.0.0.1"
	(is_linux) && IP="$DOCKSAL_DEFAULT_IP"
	echo "IP: $IP"

	echo "MYSQL:" $(docker-compose port db 3306 2>/dev/null | sed "s/0\.0\.0\.0/$IP/")
	[[ "$1" == "env" ]] && return

	echo
	echo "Docker Compose configuration"
	echo "---------------------"
	docker-compose config
	echo "---------------------"
}

config_generate ()
{
	local stack_file="$(get_config_dir_dc)/stacks/stack-default-static.yml"

	if [[ ! -f ${stack_file} ]]; then
		echo-error "Stack file does not exist: $stack_file" "Try running ${yellow}fin update${NC}"
		exit 1
	fi

	if [[ -f ".docksal/docksal.yml" ]]; then
		echo-yellow ".docksal/docksal.yml already exists"
		_confirm "Do you want to proceed and overwrite it?"
	fi

	# Create .docksal directory if it does not exist
	mkdir -p ".docksal"
	# Create docksal.env if it does not exist
	touch ".docksal/docksal.env" && \
	# remove DOCKSAL_STACK from env file if present
	(cat ".docksal/docksal.env" | sed "s/^DOCKSAL_STACK=.*//" | tee ".docksal/docksal.env" >/dev/null) && \
	# Override docksal.yml with the default stack file
	cp -f "$stack_file" ".docksal/docksal.yml"

	local DOCROOT="${DOCROOT:-docroot}"
	# Create a basic docroot and index.php if not present
	if [[ ! -d "$DOCROOT" ]] || [[ ! -f "$DOCROOT/index.php" ]]; then
		# Setup docroot and a basic index.php
		mkdir -p "$DOCROOT" &&
		echo '<?php phpinfo();' > "$DOCROOT/index.php"
	fi

	if [[ $? == 0 ]]; then
		echo-green "Configuration was generated. You can start it with ${yellow}fin start${NC}"
	else
		echo-error "Something went wrong. Check error messages above."
	fi
}

#-------------------------- RUNTIME STARTS HERE ----------------------------

# Override PATH to use our utilities
PATH="$CONFIG_BIN_DIR:$PATH"

# Set global variable in case native Docker app is used/not-used
DOCKER_NATIVE="${DOCKER_NATIVE:-0}"

# UID of user to use in cli container. Only override if you know what you're doing
FIN_SET_UID=""

# Load environment variables overrides, use to permanently override some variables
[[ -f "$CONFIG_ENV" ]] && source "$CONFIG_ENV"

# Generate Docksal instance uuid if not available
if [[ "$DOCKSAL_UUID" == "" ]]; then
	export DOCKSAL_UUID=$(uuidgen)
	echo "DOCKSAL_UUID=$DOCKSAL_UUID" | tee -a "$CONFIG_ENV" >/dev/null
fi

# Export environment variables to properly reach Docker server
if [[ "$DOCKER_NATIVE" == "1" ]]; then
	# no vm used
	export DOCKER_HOST=""
	# Host IP on Docker for Mac
	export DOCKSAL_HOST_IP="$DOCKSAL_HOST_IP_NATIVE"
else
	# get active machine and it's status
	__current_active_machine=$(cat "$CONFIG_MACHINE_ACTIVE" 2>/dev/null || echo '')
	DOCKER_MACHINE_NAME="${__current_active_machine:-$DEFAULT_MACHINE_NAME}"
	DOCKER_MACHINE_STATUS=$(docker-machine status "$DOCKER_MACHINE_NAME" 2>&1 || echo '')
	if [[ "$DOCKER_MACHINE_STATUS" == 'Running' ]]; then
		# Use cached environment variables if possible
		[[ -f "$CONFIG_MACHINES_ENV" ]] &&
			eval $(cat "$CONFIG_MACHINES_ENV") ||
			docker_machine_env
	fi
	# current active machine folder
	DOCKER_MACHINE_FOLDER="$CONFIG_MACHINES/$DOCKER_MACHINE_NAME"
	mkdir -p "$DOCKER_MACHINE_FOLDER"

	# TODO: revise or remove later. search for DOCKER_MACHINE_IP in the code
	# get desired ip
	# if [[ -f "$DOCKER_MACHINE_FOLDER/ip" ]]; then
	#	DOCKER_MACHINE_IP=$(cat "$DOCKER_MACHINE_FOLDER/ip")
	#fi
	#DOCKER_MACHINE_IP=${DOCKER_MACHINE_IP:-$DOCKSAL_DEFAULT_IP}

	export DOCKSAL_HOST_IP="$DOCKSAL_HOST_IP_BOOT2DOCKER"
fi

# Handle Alias
if [[ "$1" == "@"* ]]; then
	USED_ALIAS=${1#@}
	shift
	# Search alias first between aliases then between running projects
	if [[ -h "$CONFIG_ALIASES/$USED_ALIAS" ]]; then
		# alias found
		_alias_cd=$(readlink "$CONFIG_ALIASES/$USED_ALIAS")
	else
		# alias not found. search project names
		_alias_projects=$(docker ps --all \
			--filter 'label=com.docker.compose.service=web' \
			--format '{{.Label "com.docker.compose.project"}}\t{{.Label "io.docksal.project-root"}}')
		if (echo "$_alias_projects" | grep "^$USED_ALIAS\t" >/dev/null 2>/dev/null); then
			# project found
			_alias_cd=$(echo "$_alias_projects" | grep "^$USED_ALIAS\t" | cut -d$'\t' -f 2)
		else
			# nothing was found. error out
			echo-red "No such alias $USED_ALIAS"
			exit 1
		fi
	fi
	[[ "$1" == "" ]] && echo "$_alias_cd" && exit
	cd "$_alias_cd" 2>/dev/null
	if_failed_error "Could not navigate to directory linked by $1 alias"
fi

# TODO: figure out a better way to determine when to skip load_configuration
# Load YML files and check for updates except some cases
[[ "$1" != "update" ]] &&
	[[ "$1" != "install" ]] &&
	[[ "$1" != "version" ]] &&
	[[ "$1" != "-v" ]] &&
	[[ "$1" != "v" ]] &&
	[[ "$1" != "sysinfo" ]] &&
	[[ "$1" != "bash_comp_words" ]] &&
	[[ "$1" != "ssh-add" ]] &&
	[[ "$1" != "vm" ]] &&
	[[ "$1" != "docker" ]] &&
	[[ "$1" != "d" ]] &&
	[[ "$1" != "docker-machine" ]] &&
	[[ "$1" != "dm" ]] &&
	[[ "$1" != "exec-url" ]] &&
	[[ "$1" != "cleanup" ]] &&
	[[ "$1" != "help" ]] &&
	[[ "$*" != "" ]] &&
	[[ "$1" != "fix-smb" ]] &&
	[[ "$1" != "alias" ]] &&
	[[ "$*" != "reset dns" ]] &&
	[[ "$*" != "reset proxy" ]] &&
	[[ "$*" != "reset ssh-agent" ]] &&
	[[ "$*" != "reset system" ]] &&
	[[ "$1" != "projects" ]] &&
	[[ "$1" != "rc" ]] &&
	load_configuration &&
	[[ "$NO_UPDATES" != "1" ]] && check_for_updates

# Parse command line parameters
case "$1" in
	bash_comp_words)
		shift
		bash_comp_words "$@"
		;;
	up|start)
		shift
		up
		;;
	stop)
		shift
		stop "$@"
		;;
	restart)
		shift
		restart
		;;
	image)
		shift
		case "$1" in
			save)
				shift
				image_save "$@"
			;;
			load)
				shift
				image_load "$@"
			;;
			registry)
				shift
				image_registry_list "$@"
			;;
			*)
				echo -e "Unknown command $1. See ${yellow}fin help image${NC}"
				exit 1
			;;
		esac
		;;
	project)
		shift
		case "$1" in
			create)
				project_create
				;;
			list)
				shift
				project_list "$@"
				;;
			*)
				echo -e "Unknown command $1. See ${yellow}fin help project${NC}"
				exit 1
				;;
		esac
		;;
	status|ps)
		project_status
		;;
	# TODO: remove "projects" alias in July 2017
	projects|pl)
		shift
		project_list "$@"
		;;
	reset)
		shift
		reset "$@"
		;;
	remove|rm)
		shift
		remove "$@"
		;;
	vm)
		shift
		vm "$@"
		;;
	install)
		echo -e "${yellow}fin install${NC} is deprecated, please use ${yellow}fin update${NC} instead"
		;;
	update)
		shift
		if [[ "$1" == "--system-images" ]]; then
			update_system_images
		elif [[ "$1" == "--project-images" ]]; then
			update_project_images
		elif [[ "$1" == "--self" ]]; then
			echo "Downloading $URL_FIN"
			curl -kfsSL "$URL_FIN?r=$RANDOM" | sudo tee "$FIN_PATH" >/dev/null
			[ $? -eq 0 ] && echo "Done"
			exit
		elif [[ "$1" == "--tools" ]]; then
			update_tools
		elif [[ "$1" == "--config" ]]; then
			update_config_files
		elif [[ "$1" == "--bash-complete" ]]; then
			install_bash_autocomplete
		elif [[ "$1" != "" ]]; then
			echo -e "${yellow}fin update${NC} does not support this parameter"
		else
			update
		fi
		;;
	bash)
		shift
		_bash "$@"
		;;
	exec|run)
		shift
		if [ -f "$1" ]; then
			# if a file is passed then run it inside cli container
			[ "$(get_project_path)" == "" ] && echo "Should be run inside a project" && exit 1
			_exec "PROJECT_ROOT=/var/www DOCROOT=$DOCROOT VIRTUAL_HOST=$VIRTUAL_HOST /bin/bash $1"
		else
			_exec "$@"
		fi
		;;
	run-cli|rc)
		shift
		run_cli "$@"
		;;
	mysql|sqlc)
		shift
		mysql "$@"
		;;
	mysql-list|sqls)
		shift
		mysql_list "$@"
		;;
	mysql-import|sqli)
		shift
		mysql_import "$@"
		;;
	mysql-dump|sqld)
		shift
		mysql_dump "$@"
		;;
	drush)
		shift
		if [[ $1 == "" ]]; then
			_exec drush
		else
			_exec drush "$@"
		fi
		;;
	drupal)
		shift
		if [[ "$1" == "" ]]; then
			_exec drupal
		else
			_exec drupal "$@"
		fi
		;;
	wp)
		shift
		if [[ "$1" == "" ]]; then
			_exec wp
		else
			_exec wp "$@"
		fi
		;;
	ssh-add)
		shift
		ssh_add "$@"
		;;
	docker|d)
		shift
		is_docker_running # exports env
		check_winpty_found
		${winpty} docker "$@"
		;;
	docker-compose|dc)
		shift
		is_docker_running # exports env
		docker-compose "$@"
		;;
	docker-machine|dm)
		shift
		is_docker_running # exports env
		docker-machine "$@"
		;;
	debug)
		shift
		eval "$@"
		;;
	exec-url)
		shift
		exec_url "$@"
		;;
	share)
		ngrok_share
		;;
	cleanup)
		shift
		cleanup $1
		;;
	-v | v)
		version --short
		;;
	version)
		version
		;;
	logs)
		shift
		logs "$@"
		;;
	"")
		show_help
		;;
	help)
		show_help "$2"
		;;
	sysinfo)
		sysinfo
		;;
	config)
		shift
		if [[ "$1" == "generate" ]]; then
			shift;
			config_generate
		else
			config_show "$@"
		fi
		;;
	fix-smb)
		smb_windows_fix
		;;
	alias)
		shift
		[[ "$*" == "" ]] && alias_list && exit
		[[ "$*" == "list" ]] && alias_list && exit
		[[ "$1" == "remove" ]] && shift && alias_remove "$@" && exit
		alias_create "$@"
		;;
	# TODO: remove create-site in September 2017 in favor of project create
	create-site)
		echo -e "${yellow}Notice:${NC} create-site is deprecated and will be removed. Use ${yellow}fin project create${NC} instead."
		project_create
		;;
	init|*)
		# Search for custom commands in $DOCKSAL_COMMANDS_PATH
		# First search project commands folder
		command_script="$(get_project_path)/$DOCKSAL_COMMANDS_PATH/$1"
		# If not found search global docksal commands folder
		[ ! -f "$command_script" ] && command_script="$HOME/$DOCKSAL_COMMANDS_PATH/$1"
		# If not found there as well then it is a wrong command
		[ ! -f "$command_script" ] && \
			echo-yellow "Unknown command '$*'. See 'fin help' for list of available commands" && \
			exit 1

		# if it's not executable let's fix it
		if [[ ! -x "$command_script" ]]; then
			echo -e "${yellow}$command_script${NC} is not set to be executable."
			_confirm "Fix automatically?"
			chmod +x "$command_script"
			if_failed "Could not make $command_script executable"
		fi

		# if it has windows line endings let's fix it
		fix_crlf_warning "$command_script"

		shift
		exec "$command_script" "$@"
esac