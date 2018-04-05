#!/usr/bin/env bats

# Run server.bats before.

@test "fin:init" {
  rm -f -r drupal-8-demo
  ../bin/acp.sh cup
  git clone https://github.com/andock-ci/drupal-8-demo.git
  cd drupal-8-demo
  ../../bin/acp.sh fin init
}

