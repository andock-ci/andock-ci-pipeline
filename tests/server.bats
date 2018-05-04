#!/usr/bin/env bats

@test "connect" {
  ssh-keygen -R "dev.andock-ci.io"
  ../bin/acp.sh connect "default" "dev.andock-ci.io" "root"
}

@test "server:ssh-add" {
  ../bin/acp.sh server:ssh-add "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDG3lIf8MCPBFrOR2UaVMGfrfkP61GqOJRydMoqrJBvC2fQDXFUuVJ1HcSr4UtYpYGcGcaShJk4hE0JhvSdq/mzchbRuOxK1nV2prr/2fLRetpFxKteH/jYdcOeg1Iv53WX3KxUdE0pfTDsMVlSkZK3a47/gRgXUk5/o/L5M4QLsFeD7G6pQEDfVWJEO+mrcIuO6k21qhyH+1+WC4G0tdvEzhQVkmkZx7RLKAIjU0uJ+NJS7tLE8E0y/b/fle+kxwpNGl9Fl9Xtex9ZgC8n9syHq8K+B7YsiagUR5TsI0iYQV1kBRrcqyoH/uCaCWYIUabIlpkp9j+8Itrinjs29ItD cw@cw-sony-s"
}

@test "server:install" {
  ../bin/acp.sh server:install "andock-ci"
}


