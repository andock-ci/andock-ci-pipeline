#!/bin/bash

ANDOCK_CI_VERSION=0.0.5

REQUIREMENTS_ANDOCK_CI_BUILD='0.0.2'
REQUIREMENTS_ANDOCK_CI_TAG='0.0.2'
REQUIREMENTS_ANDOCK_CI_FIN='0.0.5'


ANDOCK_CI_PATH="/usr/local/bin/acp"
ANDOCK_CI_PATH_UPDATED="/usr/local/bin/acp.updated"

ANDOCK_CI_HOME="$HOME/.andock-ci"
ANDOCK_CI_INVENTORY="$ANDOCK_CI_HOME/inventories"
ANDOCK_CI_PLAYBOOK="$ANDOCK_CI_HOME/playbooks"

URL_REPO="https://raw.githubusercontent.com/andock-ci/pipeline"
URL_ANDOCK_CI="${URL_REPO}/master/bin/acp.sh"


export ANSIBLE_ROLES_PATH="${ANDOCK_CI_HOME}/roles"

export ANSIBLE_HOST_KEY_CHECKING=False

# @author Leonid Makarov
# Console colors
red='\033[0;91m'
red_bg='\033[101m'
green='\033[0;32m'
green_bg='\033[42m'
yellow='\033[1;33m'
NC='\033[0m'

#------------------------------ Help functions --------------------------------

# Check whether we have a working c.
# Otherwise we are running in a non-tty environment ( e.g. Babun on Windows).
# We assume the environment is interactive if there is a tty.
# All other direct checks don't work well in and every environment and scripts.
# @author Leonid Makarov
is_tty ()
{

	[[ "$(/usr/bin/tty || true)" != "not a tty" ]]

	# TODO: rewrite this check using [ -t ] test
	# http://stackoverflow.com/questions/911168/how-to-detect-if-my-shell-script-is-running-through-a-pipe/911213#911213
	# 0: stdin, 1: stdout, 2: stderr
	# [ -t 0 -a -t 1 ]
}

# Yes/no confirmation dialog with an optional message
# @param $1 confirmation message
# @author Leonid Makarov
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

# Nicely prints command help
# @param $1 command name
# @param $2 description
# @param $3 [optional] command color
# @author Oleksii Chekulaiev
printh ()
{
  local COMMAND_COLUMN_WIDTH=25;
  case "$3" in
  yellow)
    printf "  ${yellow}%-${COMMAND_COLUMN_WIDTH}s${NC}" "$1"
    echo -e "  $2"
  ;;
  green)
    printf "  ${green}%-${COMMAND_COLUMN_WIDTH}s${NC}" "$1"
    echo -e "  $2"
  ;;
  *)
    printf "  %-${COMMAND_COLUMN_WIDTH}s" "$1"
    echo -e "  $2"
  ;;
esac

}

# @author Leonid Makarov
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


# Like if_failed but with more strict error
# @author Leonid Makarov
if_failed_error ()
{
  if [ ! $? -eq 0 ]; then
    echo-error "$@"
    exit 1
  fi
}

# Ask for input
# @param $1 Question
_ask ()
{
	# Skip checks if not running interactively (not a tty or not on Windows)
	read -p "$1 : " answer
	echo $answer
}


#------------------------------ SETUP --------------------------------
# Generatec playbook files
generate_playbooks()
{
  mkdir -p $ANDOCK_CI_PLAYBOOK
  echo "---
- hosts: andock-ci-build-server
  roles:
    - { role: andock-ci.build }
" > "${ANDOCK_CI_PLAYBOOK}/build.yml"

  echo "---
- hosts: andock-ci-fin-server
  gather_facts: false
  roles:
    - { role: andock-ci.fin, git_repository_path: \"{{ git_target_repository_path }}\" }
" > "${ANDOCK_CI_PLAYBOOK}/fin.yml"

  echo "---
- hosts: andock-ci-build-server
  roles:
    - { role: andock-ci.tag, git_repository_path: \"{{ git_source_repository_path }}\" }
" > "${ANDOCK_CI_PLAYBOOK}/tag_source.yml"

  echo "---
- hosts: andock-ci-build-server
  roles:
    - { role: andock-ci.tag, git_repository_path: \"{{ git_target_repository_path }}\" }
" > "${ANDOCK_CI_PLAYBOOK}/tag_target.yml"
}


# Install ansible galaxy roles
install_pipeline()
{

  echo-green ""
  echo-green "Installing andock-ci version: ${ANDOCK_CI_VERSION} ..."

  echo-green ""
  echo-green "Installing ansible:"
  apt-get install sudo;

  sudo apt-get update
  sudo apt-get install whois -y
  sudo apt-get install build-essential libssl-dev libffi-dev python-dev -y

  set -e
  wget https://bootstrap.pypa.io/get-pip.py
  sudo python get-pip.py
  sudo pip install ansible

  export ANSIBLE_RETRY_FILES_ENABLED="False"
  generate_playbooks
  echo-green "Installing roles:"
  ansible-galaxy install andock-ci.build,v${REQUIREMENTS_ANDOCK_CI_BUILD} --force
  ansible-galaxy install andock-ci.tag,v${REQUIREMENTS_ANDOCK_CI_TAG} --force
  ansible-galaxy install andock-ci.fin,v${REQUIREMENTS_ANDOCK_CI_FIN} --force
  echo-green ""
  echo-green "ANDOCK-CI PIPELINE WAS INSTALLED SUCCESSFULLY"
}

# Based on docksal update script
# @author Leonid Makarov
self_update()
{
  echo-green "Updating andock_ci..."
  local new_andock_ci
  new_andock_ci=$(curl -kfsSL "$URL_ANDOCK_CI?r=$RANDOM")
  if_failed_error "andock_ci download failed."

# Check if fin update is required and whether it is a major version
  local new_version=$(echo "$new_andock_ci" | grep "^ANDOCK_CI_VERSION=" | cut -f 2 -d "=")
  if [[ "$new_version" != "$ANDOCK_CI_VERSION" ]]; then
    local current_major_version=$(echo "$ANDOCK_CI_VERSION" | cut -d "." -f 1)
    local new_major_version=$(echo "$new_version" | cut -d "." -f 1)
    if [[ "$current_major_version" != "$new_major_version" ]]; then
      echo -e "${red_bg} WARNING ${NC} ${red}Non-backwards compatible version update${NC}"
      echo -e "Updating from ${yellow}$ANDOCK_CI_VERSION${NC} to ${yellow}$new_version${NC} is not backward compatible."
      _confirm "Continue with the update?"
    fi

    # saving to file
    echo "$new_andock_ci" | sudo tee "$ANDOCK_CI_PATH_UPDATED" > /dev/null
    if_failed_error "Could not write $ANDOCK_CI_PATH_UPDATED"
    sudo chmod +x "$ANDOCK_CI_PATH_UPDATED"
    echo-green "andock-ci $new_version downloaded..."

  # overwrite old fin
    sudo mv "$ANDOCK_CI_PATH_UPDATED" "$ANDOCK_CI_PATH"
    install_pipeline
    exit
  else
    echo-rewrite "Updating andock-ci... $ANDOCK_CI_VERSION ${green}[OK]${NC}"
  fi
}


#------------------------------ HELP --------------------------------
show_help ()
{
  printh "Andock-ci Pipeline command reference" "${ANDOCK_CI_VERSION}" "green"

  printh "config" "Project configuration" "yellow"
  printh "config-generate" "Generate andock-ci configuration for the project"
	echo
	printh "connect" "Connect andock-ci pipeline to andock-ci server"
	echo
	printh "build/tag" "Project build management" "yellow"
  printh "build" "Build project and commit it to branch-build on target git repository"
  printh "tag" "Create git tags on both source repository and target repository"
  echo
	printh "fin <command>" "Docksal instance management on andock-ci server" "yellow"
	printh "fin up"  "Clone target git repository and start project services for your builded branch"
	printh "fin update"  "Update target git repository and project services "
	printh "fin test"  "Run tests on target project services"
	printh "fin stop" "Stop project services"
	printh "fin rm" "Remove cloned repository and project services"
	echo
	echo
	printh "version (v, -v)" "Print andock-ci version. [v, -v] - prints short version"
	echo
  printh "self-update" "${yellow}Update andock-ci${NC}" "yellow"
}
# Display acp version
# @option --short - Display only the version number
version ()
{
	if [[ $1 == '--short' ]]; then
		echo "$ANDOCK_CI_VERSION"
	else
		echo "andock-ci pipeline (acp) version: $ANDOCK_CI_VERSION"
		echo "Roles:"
		echo "andock-ci.build: $REQUIREMENTS_ANDOCK_CI_BUILD"
		echo "andock-ci.fin: $REQUIREMENTS_ANDOCK_CI_FIN"
		echo "andock-ci.tag: $REQUIREMENTS_ANDOCK_CI_TAG"
	fi

}

#----------------------- ENVIRONMENT HELPER FUNCTIONS ------------------------

# Returns the git origin repository url
get_git_origin_url ()
{
  echo $(git config --get remote.origin.url)
}
# Returns the default project name
get_default_project_name ()
{
  if ["${ANDOCK_CI_PROJECT_NAME}" != ""]; then

    echo $(basename "$PWD")
  else
    echo ${ANDOCK_CI_PROJECT_NAME}
  fi
}


# Returns the path of andock-ci.yml file
get_settings_path ()
{
	echo "$PWD/.andock-ci/andock-ci.yml"
}

# Returns the git branch name
# of the current working directory
get_current_branch ()
{
if [ "${TRAVIS}" = "true" ]; then
  echo $TRAVIS_BRANCH
else
  branch_name="$(git symbolic-ref HEAD 2>/dev/null)" ||
  branch_name="(unnamed branch)"     # detached HEAD
  branch_name=${branch_name##refs/heads/}
  echo $branch_name
fi
}

#----------------------- ANSIBLE PLAYBOOK WRAPPERS ------------------------

# Generate ansible inventory files
run_connect ()
{
  if [ "$1" = "" ]; then
    local host=$(_ask "Please enter andock-ci server domain or ip")
  else
    local host=$1
    shift
  fi
  mkdir -p $ANDOCK_CI_HOME
  mkdir -p $ANDOCK_CI_INVENTORY

  echo "
[andock-ci-build-server]
localhost ansible_connection=local
" > "${ANDOCK_CI_INVENTORY}/build"

  echo "
[andock-ci-fin-server]
$host ansible_connection=ssh ansible_ssh_user=andock-ci
" > "${ANDOCK_CI_INVENTORY}/fin"

}
check_connect()
{
  if [ ! -f "${ANDOCK_CI_INVENTORY}/$1" ]; then
    run_connect
  fi
}
# Ansible playbook wrapper for andock-ci.build role
run_build ()
{
  check_connect "build"
  local settings_path=$(get_settings_path)
  local branch_name=$(get_current_branch)

  local skip_tags=""
  if [ "${TRAVIS}" = "true" ]; then
    skip_tags="--skip-tags=\"setup,checkout\""
  else
    printh "Building branch <${branch_name}>..." "" "green"
  fi

  ansible-playbook -i "${ANDOCK_CI_INVENTORY}/build" -e "@${settings_path}" -e "project_path=$PWD build_path=$PWD branch=$branch_name" $skip_tags "$@" ${ANDOCK_CI_PLAYBOOK}/build.yml
  echo-green "BRANCH ${branch_name} BUILDED SUCCESSFULLY"
}


# Ansible playbook wrapper to role andock-ci.tag
run_tag ()
{
  check_connect "build"
  local settings_path=$(get_settings_path)
  local branch_name=$(get_current_branch)
  ansible-playbook -i "${ANDOCK_CI_INVENTORY}/build" -e "@${settings_path}" -e "build_path=${PWD}/.andock-ci/tag_source branch=${branch_name}" "$@" ${ANDOCK_CI_PLAYBOOK}/tag_source.yml
  ansible-playbook -i "${ANDOCK_CI_INVENTORY}/build" -e "@${settings_path}" -e "build_path=${PWD}/.andock-ci/tag_target branch=${branch_name}-build" "$@" ${ANDOCK_CI_PLAYBOOK}/tag_target.yml
  echo-green "TAGS GENERATED SUCCESSFULLY"
}


# Ansible playbook wrapper for role andock-ci.fin
run_fin ()
{
  check_connect "fin"
  local settings_path=$(get_settings_path)
  local branch_name=$(get_current_branch)
  local tag=$1

  case $tag in
    init|up|update|test|stop|rm)
      echo starting
    ;;
    *)
      echo-yellow "Unknown tag '$tag'. See 'acp help' for list of available commands" && \
      exit 1
    ;;
  esac
  shift
  ansible-playbook -i "${ANDOCK_CI_INVENTORY}/fin" --tags $tag -e "@${settings_path}" -e "project_path=$PWD branch=${branch_name}" "$@" ${ANDOCK_CI_PLAYBOOK}/fin.yml
  echo-green "FIN ${tag} FINISHED SUCCESSFULLY"
}


#---------------------------------- GENERATE ---------------------------------

config_generate_empty_hook()
{
  echo "---" > ".andock-ci/hooks/$1_tasks.yml"

}
config_generate ()
{
	if [[ -f ".andock-ci/andock-ci.yml" ]]; then
		echo-yellow ".andock-ci/andock-ci.yml already exists"
		_confirm "Do you want to proceed and overwrite it?"
	fi

  local project_name=$(get_default_project_name)
  local git_source_repository_path=$(get_git_origin_url)
  local domain=$(_ask 'Please enter project dev domain. [Like: dev.project.com. Url is: branch.dev.project.com]')
  local git_target_repository_path=$(_ask "Please enter git target repository path. [Leave empty to use ${git_source_repository_path}]")
  if [ "$git_target_repository_path" = "" ]; then
    git_target_repository_path=$git_source_repository_path
  fi
  mkdir -p ".andock-ci"
  mkdir -p ".andock-ci/hooks"

  echo "project_name: \"${project_name}\"
domain: \"${domain}\"
git_source_repository_path: ${git_source_repository_path}
git_target_repository_path: ${git_target_repository_path}
hook_build_tasks: \"{{project_path}}/.andock-ci/hooks/build_tasks.yml\"
hook_init_tasks: \"{{project_path}}/.andock-ci/hooks/init_tasks.yml\"
hook_update_tasks: \"{{project_path}}/.andock-ci/hooks/update_tasks.yml\"
hook_test_tasks: \"{{project_path}}/.andock-ci/hooks/test_tasks.yml\"
" > .andock-ci/andock-ci.yml

  config_generate_empty_hook "build"

  config_generate_empty_hook "init"

  config_generate_empty_hook "update"

  config_generate_empty_hook "test"

  if [[ $? == 0 ]]; then
    echo-green "Configuration was generated. Configure your hooks and start the pipeline with ${yellow}acp build${NC}"
  else
    echo-error "Something went wrong. Check error messages above."
  fi
}

#----------------------------------- MAIN -------------------------------------

case "$1" in
  _install-pipeline)
    shift
    install_pipeline "$@"
  ;;

  self-update)
    shift
    shift
    self_update "$@"
  ;;
  generate-playbooks)
    shift
    shift
    generate_playbooks
  ;;
  config-generate)
    shift
    shift
    config_generate
  ;;

   connect)
	  shift
	  run_connect "$@"
  ;;
   build)
	  shift
	  run_build "$@"
  ;;
  tag)
    shift
	  run_tag "$@"
  ;;
  fin)
	  shift
	  run_fin "$@"
  ;;
  help|"")
	  shift
    show_help
  ;;
  -v | v)
    version --short
  ;;
  version)
	  version
  ;;
	*)
		[ ! -f "$command_script" ] && \
			echo-yellow "Unknown command '$*'. See 'acp help' for list of available commands" && \
			exit 1
		shift
		exec "$command_script" "$@"
esac

