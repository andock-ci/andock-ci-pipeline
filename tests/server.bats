#!/usr/bin/env bats

@test "connect" {
  ssh-keygen -R "192.168.33.10"
  ../bin/acp.sh connect "192.168.33.10" "root" "vagrant" "andock-ci"
}

@test "server:install" {
  vagrant destroy -f
  vagrant up
  ssh-keygen -R "192.168.33.10"
  ../bin/acp.sh _update-configuration
  ../bin/acp.sh connect "192.168.33.10" "root" "vagrant" "andock-ci"
  ../bin/acp.sh server:install "andock-ci"
}
@test "server:ssh-add" {
  ../pipeline/bin/acp.sh server:ssh-add "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDNNJE637eb7ZIUP02i9B+feyBTHmhmDbCjXB5iPUBcVDu/BO1YdTWXeaAdjg4dAy7Kq5YKG+BeAcxoNe67WcNiyvvhZaaIwd4tFmTl6BA1QfpSub+fb67LQz33xm0b2+gZcv5iTsU6E0KK+fZHwCXEAd7Ac27bv7nWnJB7aRSjXvFwetb/afpa5qMjteEN2oIomSgrT1GXaleKNhW0R58z1DigtQLACwRPbmSLGWeZ2+Li9wbIZgIHpNqj51qA6W7kQM2FivjVnbsFhBi3hUvYQabrB4NWZwoLbQ/shEogJsUIKFp/JDm1Sov8EVW0D8l5rZToGPAv/j27osRiR9wKZbnthmxLRuRaot9v7gSIZwONEpjhTj/McV3arLNBsEbR27ERg9LYJE3h9YdVeVb3W0wwllU8SryFjMypaPSsEq1JFVFQUNEyD9Wx9WbencR/uUXMDTIp1KeSGU+r/ElRsi/8H6N0XEt5+StULdfOb8l9OCOdVVq5fqQUVTNvtjGSGqTVRLVm9wGFfZ0tfwVXy+TFYtXcB6oLv4Y0Dr201aXkj3Mq3UQf3qCkZLcK0jFIoGy1M9EKbTfI+lEv5m4eoWRXI1oPzftKotaiMqWOHvPMgbvpMQMDcxq/ETUJyLO+uMOsm5BHIcZnDg4WDOp9FgRMAsBAdV3Zc3ZAyRj3bw== andock@andock-ci"
}

