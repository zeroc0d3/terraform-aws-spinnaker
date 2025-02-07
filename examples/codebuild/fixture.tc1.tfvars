name   = "codebuild"
stack  = "dev"
detail = "tc1"
tags = {
  env  = "dev"
  test = "tc1"
}
aws_region = "ap-northeast-2"
project = {
  source = {
    type      = "GITHUB"
    location  = "https://github.com/aws-samples/aws-codebuild-samples.git"
    buildspec = "buildspec.yml"
    version   = "master"
  }
  environment = {
    image           = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    privileged_mode = true
  }
}
