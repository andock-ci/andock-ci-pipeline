#!/usr/bin/env bats

setup() {
  cd drupal-8-demo
}

@test "connect" {
  ../../bin/acp.sh connect "default" "dev.andock.ci"
}

@test "server:install" {
  ../../bin/acp.sh server:install "andock-ci" "root"
}

@test "server:ssh-add" {
  ../../bin/acp.sh server:ssh-add "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDG3lIf8MCPBFrOR2UaVMGfrfkP61GqOJRydMoqrJBvC2fQDXFUuVJ1HcSr4UtYpYGcGcaShJk4hE0JhvSdq/mzchbRuOxK1nV2prr/2fLRetpFxKteH/jYdcOeg1Iv53WX3KxUdE0pfTDsMVlSkZK3a47/gRgXUk5/o/L5M4QLsFeD7G6pQEDfVWJEO+mrcIuO6k21qhyH+1+WC4G0tdvEzhQVkmkZx7RLKAIjU0uJ+NJS7tLE8E0y/b/fle+kxwpNGl9Fl9Xtex9ZgC8n9syHq8K+B7YsiagUR5TsI0iYQV1kBRrcqyoH/uCaCWYIUabIlpkp9j+8Itrinjs29ItD dummy1"
  ../../bin/acp.sh server:ssh-add "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDNNJE637eb7ZIUP02i9B+feyBTHmhmDbCjXB5iPUBcVDu/BO1YdTWXeaAdjg4dAy7Kq5YKG+BeAcxoNe67WcNiyvvhZaaIwd4tFmTl6BA1QfpSub+fb67LQz33xm0b2+gZcv5iTsU6E0KK+fZHwCXEAd7Ac27bv7nWnJB7aRSjXvFwetb/afpa5qMjteEN2oIomSgrT1GXaleKNhW0R58z1DigtQLACwRPbmSLGWeZ2+Li9wbIZgIHpNqj51qA6W7kQM2FivjVnbsFhBi3hUvYQabrB4NWZwoLbQ/shEogJsUIKFp/JDm1Sov8EVW0D8l5rZToGPAv/j27osRiR9wKZbnthmxLRuRaot9v7gSIZwONEpjhTj/McV3arLNBsEbR27ERg9LYJE3h9YdVeVb3W0wwllU8SryFjMypaPSsEq1JFVFQUNEyD9Wx9WbencR/uUXMDTIp1KeSGU+r/ElRsi/8H6N0XEt5+StULdfOb8l9OCOdVVq5fqQUVTNvtjGSGqTVRLVm9wGFfZ0tfwVXy+TFYtXcB6oLv4Y0Dr201aXkj3Mq3UQf3qCkZLcK0jFIoGy1M9EKbTfI+lEv5m4eoWRXI1oPzftKotaiMqWOHvPMgbvpMQMDcxq/ETUJyLO+uMOsm5BHIcZnDg4WDOp9FgRMAsBAdV3Zc3ZAyRj3bw== dummy2"
}
