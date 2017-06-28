#!/bin/bash
ANDOCK_CI_PROJECT_NAME=basename "$PWD"

fin exec 'if test -e "/user/local/bin/acp";then
 curl -fsSL https://raw.githubusercontent.com/andock-ci/pipeline/master/install-pipeline | sh
fi
export ANDOCK_CI_INSIDE_DOCKSAL=true
export ANDOCK_CI_PROJECT_NAME=$ANDOCK_CI_PROJECT_NAME
acp $@'