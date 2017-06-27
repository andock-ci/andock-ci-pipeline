#!/bin/bash

fin exec "if test -e \"/user/local/bin/acp\";then
 curl -fsSL https://raw.githubusercontent.com/andock-ci/pipeline/master/install-pipeline | sh
fi
acp $@"