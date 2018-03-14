#!/usr/bin/env bats

@test "connect" {
  ssh-keygen -R "192.168.33.10"
  ../bin/acp.sh connect "192.168.33.10" "root" "vagrant" "andock-ci"
}

@test "fin:init" {

  ssh-keygen -R "192.168.33.10"
  ../bin/acp.sh _update-configuration
  ../bin/acp.sh connect "192.168.33.10" "root" "vagrant" "andock-ci"
  ../bin/acp.sh server:install "andock-ci"
}

