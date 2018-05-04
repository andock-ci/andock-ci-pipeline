#!/usr/bin/env bats

# Run server.bats before.

setup() {
    cd drupal-8-demo
}

@test "fin:init" {
  ../../bin/acp.sh fin init -e "git_target_repository_path=https://github.com/andock-ci/drupal-8-demo-build.git"
}

@test "fin:update" {
  ../../bin/acp.sh fin update -e "git_target_repository_path=https://github.com/andock-ci/drupal-8-demo-build.git"
}

@test "fin:test" {
  ../../bin/acp.sh fin test -e "git_target_repository_path=https://github.com/andock-ci/drupal-8-demo-build.git"
}

@test "fin:rm" {
  ../../bin/acp.sh fin rm -e "git_target_repository_path=https://github.com/andock-ci/drupal-8-demo-build.git"
}
