#!/bin/bash

ANSIBLE_VERSION="2.4.4"
ANDOCK_CI_VERSION=0.1.3

REQUIREMENTS_ANDOCK_CI_BUILD='0.1.0'
REQUIREMENTS_ANDOCK_CI_FIN='0.1.0'
REQUIREMENTS_ANDOCK_CI_SERVER='0.1.0'
REQUIREMENTS_SSH_KEYS='0.3'

DEFAULT_CONNECTION_NAME="andock-ci-server"

ANDOCK_CI_PATH="/usr/local/bin/acp"
ANDOCK_CI_PATH_UPDATED="/usr/local/bin/acp.updated"

ANDOCK_CI_HOME="$HOME/.andock-ci"
ANDOCK_CI_INVENTORY="$ANDOCK_CI_HOME/inventories"
ANDOCK_CI_PLAYBOOK="$ANDOCK_CI_HOME/playbooks"

URL_REPO="https://raw.githubusercontent.com/andock-ci/pipeline"
URL_ANDOCK_CI="${URL_REPO}/master/bin/acp.sh"
DEFAULT_ERROR_MESSAGE="Oops. There is probably something wrong. Check the logs."

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
# parse yml file:
  # See https://gist.github.com/pkuczynski/8665367
_parse_yaml() {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

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

# Yes/no confirmation dialog with an optional message
# @param $1 confirmation message
_confirmAndReturn ()
{
	while true; do
		read -p "$1 [y/n]: " answer
		case "$answer" in
			[Yy]|[Yy][Ee][Ss] )
				echo 0
				break
				;;
			[Nn]|[Nn][Oo] )
				echo 1
				break
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
# @author Leonid Makarov
echo-green () { echo -e "${green}$1${NC}"; }
# @author Leonid Makarov
echo-green-bg () { echo -e "${green_bg}$1${NC}"; }
# @author Leonid Makarov
echo-yellow () { echo -e "${yellow}$1${NC}"; }
# @author Leonid Makarov
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

# @author Leonid Makarov
# rewrite previous line
echo-rewrite ()
{
	echo -en "\033[1A"
	echo -e "\033[0K\r""$1"
}

# @author Leonid Makarov
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
	read -p "$1: " answer
	echo $answer
}

# Ask for password
# @param $1 Question
_ask_pw ()
{
	# Skip checks if not running interactively (not a tty or not on Windows)
	read -s -p "$1 : " answer
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
  gather_facts: true
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


  echo "---
- hosts: andock-ci-fin-server
  roles:
    - role: j0lly.ssh-keys
      ssh_keys_clean: False
      ssh_keys_user:
        andock-ci:
          - \"{{ ssh_key }}\"
" > "${ANDOCK_CI_PLAYBOOK}/server_ssh_add.yml"

  echo "---
- hosts: andock-ci-fin-server
  roles:
    - { role: andock-ci.server }
" > "${ANDOCK_CI_PLAYBOOK}/server_install.yml"

}


# Install ansible galaxy roles
install_pipeline()
{

  echo-green ""
  echo-green "Installing andock-ci pipeline version: ${ANDOCK_CI_VERSION} ..."

  echo-green ""
  echo-green "Installing ansible:"

  sudo apt-get update
  sudo apt-get install whois sudo build-essential libssl-dev libffi-dev python-dev -y

  set -e
  wget https://bootstrap.pypa.io/get-pip.py
  sudo python get-pip.py

  # Don't install own pip inside travis.
  if [ "${TRAVIS}" = "true" ]; then
    sudo pip install ansible=="${ANSIBLE_VERSION}"
  else
    wget https://bootstrap.pypa.io/get-pip.py
    sudo python get-pip.py
    sudo pip install ansible=="${ANSIBLE_VERSION}"
    rm get-pip.py
  fi

  which ssh-agent || ( sudo apt-get update -y && sudo apt-get install openssh-client -y )

  install_configuration
  echo-green ""
  echo-green "andock-ci pipeline was installed successfully"
}
install_configuration ()
{
  mkdir -p $ANDOCK_CI_INVENTORY

  export ANSIBLE_RETRY_FILES_ENABLED="False"
  generate_playbooks
  echo-green "Installing roles:"
  ansible-galaxy install andock-ci.build,v${REQUIREMENTS_ANDOCK_CI_BUILD} --force
  ansible-galaxy install andock-ci.fin,v${REQUIREMENTS_ANDOCK_CI_FIN} --force
  ansible-galaxy install andock-ci.server,v${REQUIREMENTS_ANDOCK_CI_SERVER} --force
  ansible-galaxy install j0lly.ssh-keys,v${REQUIREMENTS_SSH_KEYS} --force
  echo "
[andock-ci-build-server]
localhost ansible_connection=local
" > "${ANDOCK_CI_INVENTORY}/build"

}
# Based on docksal update script
# @author Leonid Makarov
self_update()
{
  echo-green "Updating andock-ci pipeline..."
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
    echo-green "andock-ci pipeline $new_version downloaded..."

  # overwrite old fin
    sudo mv "$ANDOCK_CI_PATH_UPDATED" "$ANDOCK_CI_PATH"
    acp cup
    exit
  else
    echo-rewrite "Updating andock-ci pipeline... $ANDOCK_CI_VERSION ${green}[OK]${NC}"
  fi
}


#------------------------------ HELP --------------------------------
show_help ()
{
  echo
  printh "andock-ci pipeline command reference" "${ANDOCK_CI_VERSION}" "green"
  echo
  printh "connect" "Connect andock-ci pipeline to andock-ci server"
  printh "(.) ssh-add <ssh-key>" "Add private SSH key <ssh-key> variable to the agent store."

  echo
  printh "Server management:" "" "yellow"
  printh "server:install" "Install andock-ci server."
  printh "server:update" "Update andock-ci server."
  printh "server:ssh-add" "Add public ssh key to andock-ci server."

  printh "server:info" "Show andock-ci server info"

  echo
  printh "Project configuration:" "" "yellow"
  printh "generate:config" "Generate andock-ci project configuration."
  echo
  printh "Project build management:" "" "yellow"
  printh "build" "Build project and push it to target branch."
  echo
  printh "Control remote docksal:" "" "yellow"
  printh "fin init"  "Clone git repository and init tasks."
  printh "fin up"  "Start services."
  printh "fin update"  "Pull changes from repository and run update tasks."
  printh "fin test"  "Run tests."
  printh "fin stop" "Stop services."
  printh "fin rm" "Remove environment."
  echo
  printh "fin-run <command> <path>" "Run any fin command."

  echo
  printh "Drush:" "" "yellow"
  printh "drush:generate-alias" "Generate drush alias."

  echo
  printh "version (v, -v)" "Print andock-ci version. [v, -v] - prints short version"
  printh "alias" "Print andock-ci alias."
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
		echo "andock-ci.server: $REQUIREMENTS_ANDOCK_CI_SERVER"
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
  if [ "${ANDOCK_CI_PROJECT_NAME}" != "" ]; then
    echo $(basename "$PWD")
  else
    echo "${ANDOCK_CI_PROJECT_NAME}"
  fi
}

find_root_path () {
  path=$(pwd)
  while [[ "$path" != "" && ! -e "$path/.andock-ci" ]]; do
    path=${path%/*}
  done
  echo "$path"
}

check_settings_path ()
{
  local path="$PWD/.andock-ci/andock-ci.yml"
  if [ ! -f $path ]; then
    echo-error "Settings not found. Run acp generate:config"
    exit 1
  fi
}



# Returns the path to andock-ci.yml
get_settings_path ()
{
  local path="$PWD/.andock-ci/andock-ci.yml"
  echo $path
}

# Returns the path to andock-ci.yml
get_branch_settings_path ()
{
  local branch=$(get_current_branch)
  local path="$PWD/.andock-ci/andock-ci.${branch}.yml"
  if [ -f $path ]; then
    echo $path
  fi
}


get_settings()
{
  local settings_path=$(get_settings_path)
  eval $(_parse_yaml $settings_path "config_")
}


# Returns the git branch name
# of the current working directory
get_current_branch ()
{
  if [ "${TRAVIS}" = "true" ]; then
    echo $TRAVIS_BRANCH
  elif [ "${GITLAB_CI}" = "true" ]; then
    echo $CI_COMMIT_REF_NAME
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
    local connection_name=$(_ask "Please enter connection name. [andock-ci-server]")
  else
    local connection_name=$1
    shift
  fi

  if [ "$1" = "" ]; then
    local host=$(_ask "Please enter andock-ci server domain or ip")
  else
    local host=$1
    shift
  fi

  if [ "$1" = "" ]; then
    local root=$(_ask "Please enter andock-ci server root user [root]")
  else
    local root=$1
    shift
  fi

  if [ "$root" = "" ]; then
    root="root"
  fi



  mkdir -p $ANDOCK_CI_HOME

  if [ "$connection_name" = "" ]; then
      local connection_name="andock-ci-server"
  fi

  if [ "$root_pw" = "" ]; then
      local root_pw_string=""
    else
      local root_pw_string="ansible_ssh_pass=$root_pw"
  fi

  if [ "$andock_ci_pw" = "" ]; then
      local andock_ci_pw_string=""
    else
      local andock_ci_pw_string="ansible_ssh_pass=$andock_ci_pw"
  fi

  echo "
[andock-ci-fin-server]
$host ansible_connection=ssh ansible_user=andock-ci $andock_ci_pw_string
" > "${ANDOCK_CI_INVENTORY}/${connection_name}"
  echo "
[andock-ci-fin-server]
$host ansible_connection=ssh ansible_user=$root $root_pw_string
" > "${ANDOCK_CI_INVENTORY}/${connection_name}-root"
  echo-green "Connection configuration was created successfully."
}

check_connect()
{
  if [ ! -f "${ANDOCK_CI_INVENTORY}/$1" ]; then
    echo-red "No alias \"${1}\" exists. Please run acp connect."
    exit 1
  fi
}

# Ansible playbook wrapper for andock-ci.build role.
run_build ()
{
  check_settings_path
  local settings_path=$(get_settings_path)

  local branch_name=$(get_current_branch)
  echo-green "Building branch <${branch_name}>..."
  local skip_tags=""
  if [ "${TRAVIS}" = "true" ]; then
    skip_tags="--skip-tags=\"setup,checkout\""
  fi

  ansible-playbook -i "${ANDOCK_CI_INVENTORY}/build" -e "@${settings_path}" -e "project_path=$PWD build_path=$PWD branch=$branch_name" $skip_tags "$@" ${ANDOCK_CI_PLAYBOOK}/build.yml
  if [[ $? == 0 ]]; then
    echo-green "Branch ${branch_name} was builded successfully"
  else
    echo-error $DEFAULT_ERROR_MESSAGE
    exit 1;
  fi

}

# Ansible playbook wrapper for role andock-ci.fin
run_fin_run ()
{

  # Check if connection exists
  check_settings_path

  local settings_path=$(get_settings_path)

  local branch_name=$(get_current_branch)

  local connection=$1
  shift

  local exec_command=$1
  shift

  local exec_path=$1
  shift

  ansible-playbook -i "${ANDOCK_CI_INVENTORY}/${connection}" --tags "exec" -e "@${settings_path}" ${branch_settings_config} -e "exec_command='$exec_command' exec_path='$exec_path' project_path=$PWD branch=${branch_name}" ${ANDOCK_CI_PLAYBOOK}/fin.yml
  if [[ $? == 0 ]]; then
    echo-green "fin ${fin_command} was finished successfully."
  else
    echo-error $DEFAULT_ERROR_MESSAGE
    exit 1;
  fi
}

# Ansible playbook wrapper for role andock-ci.fin
run_fin ()
{

  # Check if connection exists
  check_settings_path

  local settings_path=$(get_settings_path)

  get_settings

  local branch_settings_path=$(get_branch_settings_path)

  local branch_settings_config=""
  if [ "${branch_settings_path}" != "" ]; then
      local branch_settings_config="-e @${branch_settings_path}"
  fi

  local branch_name=$(get_current_branch)

  local connection=$1
  shift

  local tag=$1
  shift

  case $tag in
    init|up|update|test|stop|rm|exec)
      echo-green "Start fin ${tag}..."
    ;;
    *)
      echo-yellow "Unknown tag '$tag'. See 'acp help' for list of available commands" && \
      exit 1
    ;;
  esac
  shift

  ansible-playbook -i "${ANDOCK_CI_INVENTORY}/${connection}" --tags $tag -e "@${settings_path}" ${branch_settings_config} -e "project_path=$PWD branch=${branch_name}" ${ANDOCK_CI_PLAYBOOK}/fin.yml
  if [[ $? == 0 ]]; then
    echo-green "fin ${tag} was finished successfully."
    local domains=$(echo $config_domain | tr " " "\n")
    for domain in $domains
    do
        local url="http://${branch_name}.${domain}"
        echo-green  "See [$url]"
    done
  else
    echo-error $DEFAULT_ERROR_MESSAGE
    exit 1;
  fi
}


#---------------------------------- GENERATE ---------------------------------
generate_config_fin_hook()
{
  echo "- name: Init andock-ci environment
  command: \"fin $1\"
  args:
    chdir: \"{{ docroot_path }}\"
  when: environment_exists_before == false
" > ".andock-ci/hooks/$1_tasks.yml"
}

generate_config_compser_hook()
{
  echo "- name: composer install
  command: \"composer install\"
  args:
    chdir: \"{{ checkout_path }}\"
" > ".andock-ci/hooks/$1_tasks.yml"
}

generate_config_empty_hook()
{
  echo "---" > ".andock-ci/hooks/$1_tasks.yml"
}

generate_config ()
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

  if [[ $(_confirmAndReturn "Do you use composer to build your project?") == 0 ]]; then
    generate_config_compser_hook "build"
  else
    generate_config_empty_hook "build"
  fi

  generate_config_fin_hook "init"

  generate_config_empty_hook "update"

  generate_config_empty_hook "test"

  if [[ $? == 0 ]]; then
    echo-green "Configuration was generated. Configure your hooks and start the pipeline with ${yellow}acp build${NC}"
  else
    echo-error $DEFAULT_ERROR_MESSAGE
  fi
}

# Add ssh key.
ssh_add ()
{
  eval $(ssh-agent -s)
  echo "$*" | tr -d '\r' | ssh-add - > /dev/null
  mkdir -p ~/.ssh
  chmod 700 ~/.ssh
  echo-green "SSH key was added to keystore."
}

#----------------------------------- DRUSH  -----------------------------------
run_alias ()
{
  set -e
  check_settings_path
  get_settings
  local branch_name=$(get_current_branch)
  local env="${config_project_name}.${branch_name}"
  echo "${env}"
}

run_drush_generate ()
{

  set -e
  check_settings_path
  get_settings
  local branch_name=$(get_current_branch)

  local domains=$(echo $config_domain | tr " " "\n")
  for domain in $domains
    do
        local url="http://${branch_name}.${domain}"
        echo-green  "Domain: [$url]"
            echo "
\$aliases['${branch_name}'] = array (
  'root' => '/var/www/drupal',
  'uri' => '${url}',
  'remote-host' => '${url}',
  'remote-user' => 'andock-ci',
  'ssh-options' => '-o SendEnv=LC_ANDOCK_CI_ENV'
);
"
    done

}


#----------------------------------- SERVER -----------------------------------

# Add ssh key to andock-ci user.
run_server_ssh_add ()
{
  set -e
  local connection=$1
  shift
  local ssh_key="command=\"acs _bridge \$SSH_ORIGINAL_COMMAND\" $@"
  ansible-playbook -i "${ANDOCK_CI_INVENTORY}/${connection}-root" -e "ssh_key='$ssh_key'" "${ANDOCK_CI_PLAYBOOK}/server_ssh_add.yml"
  echo-green "SSH key was added."
}

# Install andock-ci.
run_server_install ()
{
  local connection=$1
  shift
  local tag=$1
  shift
  set -e
  if [ "$1" = "" ]; then
    local andock_ci_pw=$(openssl rand -base64 32)
  else
    local andock_ci_pw=$1
    shift
  fi

  local andock_ci_pw_enc=$(mkpasswd --method=sha-512 $andock_ci_pw)

  ansible andock-ci-fin-server -i "${ANDOCK_CI_INVENTORY}/${connection}-root"  -m raw -a "test -e /usr/bin/python || (apt -y update && apt install -y python-minimal)"
  ansible-playbook --tags $tag -i "${ANDOCK_CI_INVENTORY}/${connection}-root" -e "pw='$andock_ci_pw_enc'" "${ANDOCK_CI_PLAYBOOK}/server_install.yml"
  if [ "$tag" == "install" ]; then
    echo-green "andock-ci server was installed successfully."
    echo-green "andock-ci password is: $andock_ci_pw"
  else
    echo-green "andock-ci server was updated successfully."
  fi

}

#----------------------------------- MAIN -------------------------------------


# Check for connection alias.
int_connection="$1"
add="${int_connection:0:1}"

if [ "$add" = "@" ]; then
    # Connection alias found.
    connection="${int_connection:1}"
    shift
else
    # No alias found. Use the "andock-ci-server"
    connection=${DEFAULT_CONNECTION_NAME}
fi

# Than we check if the command needs an connection.
# And if yes we check if the connection exists.
case "$1" in
  server:install|server:update|server:info|fin|ssh-add)
  check_connect $connection
  echo-green "Use connection: $connection"
  ;;
esac

# ansible playbooks needs to be called from project_root.
# So cd to root path
root_path=$(find_root_path)
cd $root_path
# Store the command.
command=$1
shift

# Finally. Run command.
case "$command" in
  _install-pipeline)
    install_pipeline "$@"
  ;;
  cup)
    install_configuration "$@"
  ;;
  self-update)
    self_update "$@"
  ;;
  ssh-add)
    ssh_add $connection "$@"
  ;;
  generate-playbooks)
    generate_playbooks
  ;;
  generate:config)
    generate_config
  ;;
  connect)
	run_connect "$@"
  ;;
   build)
	run_build "$@"
  ;;
  fin)
	run_fin "$connection" $@
  ;;
  fin-run)
    run_fin_run "$connection" "$1" "$2"
  ;;
  alias)
	run_alias
  ;;
  drush:generate-alias)
	run_drush_generate
  ;;


  server:install)
	run_server_install "$connection" "install" $@
  ;;
  server:update)
	run_server_install "$connection" "update" $@
  ;;
  server:info)
	run_server_info "$connection" $@
  ;;
  server:ssh-add)
	run_server_ssh_add "$connection" $@
  ;;
  help|"")
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
			echo-yellow "Unknown command '$command'. See 'acp help' for list of available commands" && \
			exit 1
		shift
		exec "$command_script" "$@"
esac
