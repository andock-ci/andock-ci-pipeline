#!/usr/bin/env bats

# Run server.bats before.

setup() {
    cd drupal-8-demo
}

@test "fin:init" {
  ../../bin/acp.sh fin init -e "branch=master" -e "git_target_repository_path=https://github.com/andock/drupal-8-demo-build.git"
}

@test "fin:update" {
  ../../bin/acp.sh fin update -e "branch=master" -e "git_target_repository_path=https://github.com/andock/drupal-8-demo-build.git"
}

@test "fin:test" {
  ../../bin/acp.sh fin test -e "branch=master" -e "git_target_repository_path=https://github.com/andock/drupal-8-demo-build.git"
}

@test "fin:rm" {
  ../../bin/acp.sh fin rm -e "branch=master" -e "git_target_repository_path=https://github.com/andock/drupal-8-demo-build.git"
}
