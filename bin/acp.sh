#!/bin/bash

ANSIBLE_VERSION="2.4.4"
ANDOCK_CI_VERSION=0.3.8

REQUIREMENTS_ANDOCK_CI_BUILD='0.1.0'
REQUIREMENTS_ANDOCK_CI_FIN='0.2.1'
REQUIREMENTS_ANDOCK_CI_SERVER='0.1.0'
REQUIREMENTS_SSH_KEYS='0.3'

DEFAULT_CONNECTION_NAME="default"

ANDOCK_CI_PATH="/usr/local/bin/acp"
ANDOCK_CI_PATH_UPDATED="/usr/local/bin/acp.updated"

ANDOCK_CI_HOME="$HOME/.andock-ci"
ANDOCK_CI_INVENTORY="./.andock-ci/connections"
ANDOCK_CI_INVENTORY_GLOBAL="$ANDOCK_CI_HOME/connections"
ANDOCK_CI_PLAYBOOK="$ANDOCK_CI_HOME/playbooks"
ANDOCK_CI_PROJECT_NAME=""

URL_REPO="https://raw.githubusercontent.com/andock-ci/pipeline"
URL_ANDOCK_CI="${URL_REPO}/master/bin/acp.sh"
DEFAULT_ERROR_MESSAGE="Oops. There is probably something wrong. Check the logs."

export ANSIBLE_ROLES_PATH="${ANDOCK_CI_HOME}/roles"

export ANSIBLE_HOST_KEY_CHECKING=False

config_git_target_repository_path=""
config_domain=""
config_project_name=""
config_git_repository_path=""
config_git_source_repository_path=""
# @author Leonid Makarov
# Console colors
red='\033[0;91m'
red_bg='\033[101m'
green='\033[0;32m'
yellow='\033[1;33m'
NC='\033[0m'

#------------------------------ Help functions --------------------------------
# parse yml file:
# See https://gist.github.com/pkuczynski/8665367
_parse_yaml() {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*'
   local fs
   fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F"$fs" '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
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
				echo 1
				break
				;;
			[Nn]|[Nn][Oo] )
				echo 0
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
echo-yellow () { echo -e "${yellow}$1${NC}"; }
# @author Leonid Makarov
echo-error () {
	echo -e "${red_bg} ERROR: ${NC} ${red}$1${NC}";
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

# Generate playbook files
generate_playbooks()
{
    mkdir -p ${ANDOCK_CI_PLAYBOOK}
    echo "---
- hosts: andock-ci-build-server
  roles:
    - { role: andock-ci.build }
" > "${ANDOCK_CI_PLAYBOOK}/build.yml"

    echo "---
- hosts: andock-ci-docksal-server
  gather_facts: true
  roles:
    - { role: andock-ci.fin, git_repository_path: \"{{ git_target_repository_path }}\" }
" > "${ANDOCK_CI_PLAYBOOK}/fin.yml"


    echo "---
- hosts: andock-ci-docksal-server
  roles:
    - role: andock-ci.ansible_role_ssh_keys
      ssh_keys_clean: False
      ssh_keys_user:
        andock-ci:
          - \"{{ ssh_key }}\"
" > "${ANDOCK_CI_PLAYBOOK}/server_ssh_add.yml"

    echo "---
- hosts: andock-ci-docksal-server
  roles:
    - { role: andock-ci.server }
" > "${ANDOCK_CI_PLAYBOOK}/server_install.yml"

}

# Install ansible
# and ansible galaxy roles
install_pipeline()
{
    echo-green ""
    echo-green "Installing andock-ci pipeline version: ${ANDOCK_CI_VERSION} ..."

    echo-green ""
    echo-green "Installing ansible:"

    sudo apt-get update
    sudo apt-get install whois sudo build-essential libssl-dev libffi-dev python-dev -y

    set -e

    # Don't install own pip inside travis.
    if [ "${TRAVIS}" = "true" ]; then
        sudo pip install ansible=="${ANSIBLE_VERSION}"
    else
        wget https://bootstrap.pypa.io/get-pip.py
        sudo python get-pip.py
        sudo pip install ansible=="${ANSIBLE_VERSION}"
        rm get-pip.py
    fi
    sudo pip install urllib3 pyOpenSSL ndg-httpsclient pyasn1

    which ssh-agent || ( sudo apt-get update -y && sudo apt-get install openssh-client -y )

    install_configuration
    echo-green ""
    echo-green "andock-ci pipeline was installed successfully"
}

# Install ansible galaxy roles.
install_configuration ()
{
    mkdir -p $ANDOCK_CI_INVENTORY_GLOBAL
    #export ANSIBLE_RETRY_FILES_ENABLED="False"
    generate_playbooks
    echo-green "Installing roles:"
    ansible-galaxy install andock-ci.build,v${REQUIREMENTS_ANDOCK_CI_BUILD} --force
    ansible-galaxy install andock-ci.fin,v${REQUIREMENTS_ANDOCK_CI_FIN} --force
    ansible-galaxy install andock-ci.ansible_role_ssh_keys,v${REQUIREMENTS_SSH_KEYS} --force
    ansible-galaxy install andock-ci.server,v${REQUIREMENTS_ANDOCK_CI_SERVER} --force
    echo "
[andock-ci-build-server]
localhost ansible_connection=local
" > "${ANDOCK_CI_INVENTORY_GLOBAL}/build"

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
    local new_version
    new_version=$(echo "$new_andock_ci" | grep "^ANDOCK_CI_VERSION=" | cut -f 2 -d "=")
    if [[ "$new_version" != "$ANDOCK_CI_VERSION" ]]; then
        local current_major_version
        current_major_version=$(echo "$ANDOCK_CI_VERSION" | cut -d "." -f 1)
        local new_major_version
        new_major_version=$(echo "$new_version" | cut -d "." -f 1)
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

# Show help.
show_help ()
{
    echo
    printh "andock-ci pipeline command reference" "${ANDOCK_CI_VERSION}" "green"
    echo
    printh "connect" "Connect andock-ci pipeline to andock-ci server"
    printh "(.) ssh-add <ssh-key>" "Add private SSH key <ssh-key> variable to the agent store."

    echo
    printh "Server management:" "" "yellow"
    printh "server:install [root_user, default=root] [andock_ci_pass, default=keygen]" "Install andock-ci server."
    printh "server:update [root_user, default=root]" "Update andock-ci server."
    printh "server:ssh-add [root_user, default=root]" "Add public ssh key to andock-ci server."

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
    echo "$(git config --get remote.origin.url)"
}

# Returns the default project name
get_default_project_name ()
{
    if [ "${ANDOCK_CI_PROJECT_NAME}" != "" ]; then
        echo "$(basename ${PWD})"
    else
        echo "${ANDOCK_CI_PROJECT_NAME}"
    fi
}

# Returns the path project root folder.
find_root_path () {
    path=$(pwd)
    while [[ "$path" != "" && ! -e "$path/.andock-ci" ]]; do
        path=${path%/*}
    done
    echo "$path"
}

# Check for connection inventory file in .andock-ci/connections/$1
check_connect()
{
  if [ ! -f "${ANDOCK_CI_INVENTORY}/$1" ]; then
    echo-red "No alias \"${1}\" exists. Please run acp connect."
    exit 1
  fi
}

# Checks if andock-ci.yml exists.
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
    local branch
    branch=$(get_current_branch)
    local path="$PWD/.andock-ci/andock-ci.${branch}.yml"
    if [ -f $path ]; then
        echo $path
    fi
}

# Parse the .andock-ci.yaml and
# make all variables accessable.
get_settings()
{
    local settings_path
    settings_path=$(get_settings_path)
    eval "$(_parse_yaml $settings_path 'config_')"
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

# Generate ansible inventory files inside .andock-ci/connections folder.
# @param $1 The Connection name.
# @param $2 The andock-ci host name.
# @param $3 The exec path.
run_connect ()
{
  if [ "$1" = "" ]; then
    local connection_name
    connection_name=$(_ask "Please enter connection name [$DEFAULT_CONNECTION_NAME]")
  else
    local connection_name=$1
    shift
  fi

  if [ "$1" = "" ]; then
    local host=
    host=$(_ask "Please enter andock-ci server domain or ip")
  else
    local host=$1
    shift
  fi

  if [ "$connection_name" = "" ]; then
      local connection_name=$DEFAULT_CONNECTION_NAME
  fi

  mkdir -p ".andock-ci/connections"

  echo "
[andock-ci-docksal-server]
$host ansible_connection=ssh ansible_user=andock-ci
" > "${ANDOCK_CI_INVENTORY}/${connection_name}"

  echo-green "Connection configuration was created successfully."
}

# Ansible playbook wrapper for andock-ci.build role.
run_build ()
{
    check_settings_path
    local settings_path
    settings_path=$(get_settings_path)

    local branch_name
    branch_name=$(get_current_branch)
    echo-green "Building branch <${branch_name}>..."
    local skip_tags=""
    if [ "${TRAVIS}" = "true" ]; then
        skip_tags="--skip-tags=\"setup,checkout\""
    fi
    ansible-playbook -i "${ANDOCK_CI_INVENTORY_GLOBAL}/build" -e "@${settings_path}" -e "project_path=$PWD build_path=$PWD branch=$branch_name" $skip_tags "$@" ${ANDOCK_CI_PLAYBOOK}/build.yml
    if [[ $? == 0 ]]; then
        echo-green "Branch ${branch_name} was builded successfully"
    else
        echo-error ${DEFAULT_ERROR_MESSAGE}
        exit 1;
    fi
}

# Ansible playbook wrapper for role andock-ci.fin
# @param $1 The Connection.
# @param $2 The fin command.
# @param $3 The exec path.
run_fin_run ()
{

    # Check if connection exists
    check_settings_path

    # Load configuration.
    local settings_path
    settings_path=$(get_settings_path)

    # Get the current branch name.
    local branch_name
    branch_name=$(get_current_branch)

    # Set parameters.
    local connection=$1 && shift
    local exec_command=$1 && shift
    local exec_path=$1 && shift

    # Run the playbook.
    ansible-playbook -i "${ANDOCK_CI_INVENTORY}/${connection}" --tags "exec" -e "@${settings_path}" ${branch_settings_config} -e "exec_command='$exec_command' exec_path='$exec_path' project_path=$PWD branch=${branch_name}" ${ANDOCK_CI_PLAYBOOK}/fin.yml
    if [[ $? == 0 ]]; then
        echo-green "fin exec was finished successfully."
    else
        echo-error $DEFAULT_ERROR_MESSAGE
        exit 1;
    fi
}

# Ansible playbook wrapper for role andock-ci.fin
# @param $1 Connection
# @param $2 Tag
run_fin ()
{

    # Check if connection exists
    check_settings_path

    # Load settings.
    local settings_path
    settings_path="$(get_settings_path)"
    get_settings

    # Load branch specific {branch}.andock-ci.yml file if exist.
    local branch_settings_path
    branch_settings_path="$(get_branch_settings_path)"
    local branch_settings_config=""
    if [ "${branch_settings_path}" != "" ]; then
        local branch_settings_config="-e @${branch_settings_path}"
    fi

    # If no target repository path is configured no build process is expected.
    # Use source git repository as target repository path.
    # AND set target_branch_suffix='' to checkout the standard repository.
    local repository_config=""
    if [ "${config_git_target_repository_path}" == "" ]; then
        local repository_config="git_target_repository_path='${config_git_source_repository_path}' target_branch_suffix=''"
    fi
    if [ "${config_git_repository_path}" != "" ]; then
        local repository_config="git_target_repository_path='${config_git_repository_path}' target_branch_suffix=''"
    fi

    # Get the current branch.
    local branch_name
    branch_name=$(get_current_branch)

    # Set parameters.
    local connection=$1 && shift
    local tag=$1 && shift

    # Validate tag name. Show help if needed.
    case $tag in
        init|up|update|test|stop|rm|exec)
            echo-green "Start fin ${tag}..."
        ;;
        *)
            echo-yellow "Unknown tag '$tag'. See 'acp help' for list of available commands" && \
            exit 1
        ;;
    esac

    # Run the playbook.
    ansible-playbook -i "${ANDOCK_CI_INVENTORY}/${connection}" --tags $tag -e "${repository_config}" -e "@${settings_path}" ${branch_settings_config} -e "project_path=$PWD branch=${branch_name}" "$@" ${ANDOCK_CI_PLAYBOOK}/fin.yml

    # Handling playbook results.
    if [[ $? == 0 ]]; then
        echo-green "fin ${tag} was finished successfully."
        local domains
        domains=$(echo $config_domain | tr " " "\n")
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

# Generate fin hooks.
# @param $1 The hook name.
generate_config_fin_hook()
{
    echo "- name: Init andock-ci environment
  command: \"fin $1\"
  args:
    chdir: \"{{ docroot_path }}\"
  when: environment_exists_before == false
" > ".andock-ci/hooks/$1_tasks.yml"
}

# Generate composer hook.
generate_config_compser_hook()
{
    echo "- name: composer install
  command: \"composer install\"
  args:
    chdir: \"{{ checkout_path }}\"
" > ".andock-ci/hooks/$1_tasks.yml"
}

# Generate empty hook file.
# @param $1 The hook name.
generate_config_empty_hook()
{
    echo "---" > ".andock-ci/hooks/$1_tasks.yml"
}

# Generate configuration.
generate_config ()
{
    if [[ -f ".andock-ci/andock-ci.yml" ]]; then
        echo-yellow ".andock-ci/andock-ci.yml already exists"
        _confirm "Do you want to proceed and overwrite it?"
    fi
    local project_name
    project_name=$(get_default_project_name)
    local git_source_repository_path
    git_source_repository_path=$(get_git_origin_url)
    if [ "$git_source_repository_path" = "" ]; then
        echo-red "No git repository found."
        exit
    fi

    local domain && domain=$(_ask "Please enter project dev domain. [Like: dev.project.com. Url is: branch.dev.project.com]")
    local build && build=$(_confirmAndReturn "Do you want to build the project and push the result to a target repository?")
    local git_target=""
    if [ "$build" = 1 ]; then
        local git_target_repository_path
        git_target_repository_path=$(_ask "Please enter git target repository path. [Leave empty to use ${git_source_repository_path}]")
        # Set to source repository if empty.
        if [ "${git_target_repository_path}" = "" ]; then
            git_target_repository_path=${git_source_repository_path}
        fi
        local git_target="git_target_repository_path: ${git_target_repository_path}"
    fi

    mkdir -p ".andock-ci"
    mkdir -p ".andock-ci/hooks"

    echo "project_name: \"${project_name}\"
domain: \"${domain}\"
git_source_repository_path: ${git_source_repository_path}
${git_target}
hook_build_tasks: \"{{project_path}}/.andock-ci/hooks/build_tasks.yml\"
hook_init_tasks: \"{{project_path}}/.andock-ci/hooks/init_tasks.yml\"
hook_update_tasks: \"{{project_path}}/.andock-ci/hooks/update_tasks.yml\"
hook_test_tasks: \"{{project_path}}/.andock-ci/hooks/test_tasks.yml\"
" > .andock-ci/andock-ci.yml

    if [[ "$build" = 1 && $(_confirmAndReturn "Do you use composer to build your project?") == 1 ]]; then
        generate_config_compser_hook "build"
    else
        generate_config_empty_hook "build"
    fi

    generate_config_fin_hook "init"

    generate_config_empty_hook "update"

    generate_config_empty_hook "test"

    if [[ $? == 0 ]]; then
        if [ "$build" = 1 ]; then
            echo-green "Configuration was generated. Configure your hooks and start the pipeline with ${yellow}acp build${NC}"
        else
            echo-green "Configuration was generated. Configure your hooks and start the pipeline with ${yellow}acp fin init${NC}"
        fi
    else
        echo-error ${DEFAULT_ERROR_MESSAGE}
    fi
}

# Add ssh key.
ssh_add ()
{
    eval "$(ssh-agent -s)"
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
    local branch_name
    branch_name=$(get_current_branch)
    local env
    env="${config_project_name}.${branch_name}"
    echo "${env}"
}

run_drush_generate ()
{
    set -e
    check_settings_path
    get_settings
    local branch_name
    branch_name=$(get_current_branch)

    local domains
    domains=$(echo $config_domain | tr " " "\n")
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

    local ssh_key="command=\"acs _bridge \$SSH_ORIGINAL_COMMAND\" $1"
    shift

    if [ "$1" = "" ]; then
        local root_user="root"
    else
        local root_user=$1
        shift
    fi

    ansible-playbook -e "ansible_ssh_user=$root_user" -i "${ANDOCK_CI_INVENTORY}/${connection}" -e "ssh_key='$ssh_key'" "${ANDOCK_CI_PLAYBOOK}/server_ssh_add.yml"
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
        local andock_ci_pw
        andock_ci_pw=$(openssl rand -base64 32)
    else
        local andock_ci_pw=$1
        shift
    fi

    if [ "$1" = "" ]; then
        local root_user="root"
    else
        local root_user=$1
        shift
    fi

    local andock_ci_pw_enc
    andock_ci_pw_enc=$(mkpasswd --method=sha-512 $andock_ci_pw)

    ansible andock-ci-docksal-server -e "ansible_ssh_user=$root_user" -i "${ANDOCK_CI_INVENTORY}/${connection}"  -m raw -a "test -e /usr/bin/python || (apt -y update && apt install -y python-minimal)"
    ansible-playbook -e "ansible_ssh_user=$root_user" --tags $tag -i "${ANDOCK_CI_INVENTORY}/${connection}" -e "pw='$andock_ci_pw_enc'" "${ANDOCK_CI_PLAYBOOK}/server_install.yml"
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
    # No alias found. Use the "default"
    connection=${DEFAULT_CONNECTION_NAME}
fi

# Than we check if the command needs an connection.
# And if yes we check if the connection exists.
case "$1" in
    server:install|server:update|server:info|server:ssh-add|fin)
    check_connect $connection
    echo-green "Use connection: $connection"
    ;;
esac

org_path=${PWD}
# ansible playbooks needs to be called from project_root.
# So cd to root path
root_path=$(find_root_path)
cd "$root_path"

# Store the command.
command=$1
shift

# Finally. Run the command.
case "$command" in
  _install-pipeline)
    install_pipeline "$@"
  ;;
  _update-pipeline)
    install_configuration "$@"
  ;;
  cup)
    install_configuration "$@"
  ;;
  self-update)
    self_update "$@"
  ;;
  ssh-add)
    ssh_add "$@"
  ;;
  generate-playbooks)
    generate_playbooks
  ;;
  generate:config)
    cd $org_path
    generate_config
  ;;
  connect)
	run_connect "$@"
  ;;
   build)
	run_build "$@"
  ;;
  fin)
	run_fin "$connection" "$@"
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
	run_server_install "$connection" "install" "$@"
  ;;
  server:update)
	run_server_install "$connection" "update" "$@"
  ;;
  server:info)
	run_server_info "$connection" "$@"
  ;;
  server:ssh-add)
	run_server_ssh_add "$connection" "$1" "$2"
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
    echo-yellow "Unknown command '$command'. See 'acp help' for list of available commands" && \
    exit 1
esac
