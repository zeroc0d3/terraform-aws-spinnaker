name   = "vpc"
stack  = "dev"
detail = "tc1"
tags = {
  env           = "dev"
  subnet-type   = "isolated"
  nat-per-az    = "none"
  vpc_endpoints = "default"
  test          = "tc1"
}
aws_region = "ap-northeast-2"
azs        = ["ap-northeast-2a", "ap-northeast-2b", "ap-northeast-2c"]
cidr       = "10.0.0.0/16"
enable_igw = false
enable_ngw = false
