#!/bin/bash
ANDOCK_CI_PROJECT_NAME=$(basename "$PWD")
cmd="acp"
if [[ $2 != "" ]]; then
	cmd="$cmd "$(printf " %q" "$@")
else
	cmd="$cmd $*"
fi
export CONTAINER_NAME='acp'
fin exec "
if [ ! -f \"/usr/local/bin/acp\" ]; then
 curl -fsSL https://raw.githubusercontent.com/andock-ci/pipeline/master/install-pipeline | sh
fi
export ANDOCK_CI_INSIDE_DOCKSAL=true
export ANDOCK_CI_PROJECT_NAME=${ANDOCK_CI_PROJECT_NAME}
$cmd"
