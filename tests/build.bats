#!/usr/bin/env bats

# Run server.bats before.

setup() {
    cd drupal-8-demo
}

@test "build" {
  ../../bin/acp.sh build
}

