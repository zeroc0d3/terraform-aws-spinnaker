## managed continuous integration service

module "aws" {
  source = "Young-ook/spinnaker/aws//modules/aws-partitions"
}

locals {
  artifact    = lookup(var.project, "artifact", local.default_artifact)
  environment = lookup(var.project, "environment", local.default_environment)
  source      = lookup(var.project, "source", local.default_source)
}

resource "aws_codebuild_project" "cb" {
  name          = local.name
  tags          = merge(local.default-tags, var.tags)
  description   = "CodeBuild project"
  build_timeout = "5"
  service_role  = aws_iam_role.cb.arn

  artifacts {
    type                = lookup(local.artifact, "type", local.default_artifact.type)
    location            = lookup(local.artifact, "location", local.default_artifact.location)
    encryption_disabled = lookup(local.artifact, "encryption_disabled", local.default_artifact.encryption_disabled)
  }

  environment {
    type                        = lookup(local.environment, "type", local.default_environment["type"])
    image                       = lookup(local.environment, "image", local.default_environment["image"])
    compute_type                = lookup(local.environment, "compute_type", local.default_environment["compute_type"])
    image_pull_credentials_type = lookup(local.environment, "image_pull_credentials_type", local.default_environment["image_pull_credentials_type"])
    privileged_mode             = lookup(local.environment, "privileged_mode", local.default_environment["privileged_mode"])

    dynamic "environment_variable" {
      for_each = lookup(local.environment, "environment_variables", {})
      content {
        name  = environment_variable.key
        value = environment_variable.value
      }
    }
  }

  source {
    type            = lookup(local.source, "type", local.default_source["type"])
    location        = lookup(local.source, "location", local.default_source["location"])
    buildspec       = lookup(local.source, "buildspec", local.default_source["buildspec"])
    git_clone_depth = lookup(local.source, "git_clone_depth", 1)
  }
  source_version = lookup(local.source, "version", local.default_source["version"])

  dynamic "logs_config" {
    for_each = var.log != null ? var.log : {}
    content {
      dynamic "cloudwatch_logs" {
        for_each = logs_config.key == "cloudwatch_logs" ? var.log : {}
        content {
          status      = lookup(cloudwatch_logs.value, "status", null)
          group_name  = lookup(cloudwatch_logs.value, "group_name", null)
          stream_name = lookup(cloudwatch_logs.value, "stream_name", null)
        }
      }

      dynamic "s3_logs" {
        for_each = logs_config.key == "s3_logs" ? var.log : {}
        content {
          status              = lookup(s3_logs.value, "status", null)
          location            = lookup(s3_logs.value, "location", null)
          encryption_disabled = lookup(s3_logs.value, "encryption_disabled", null)
        }
      }
    }
  }

  dynamic "vpc_config" {
    for_each = toset(var.vpc != null ? ["vpc"] : [])
    content {
      vpc_id             = lookup(var.vpc, "vpc", null)
      subnets            = lookup(var.vpc, "subnets", null)
      security_group_ids = lookup(var.vpc, "security_groups", null)
    }
  }
}

# security/policy
resource "aws_iam_role" "cb" {
  name = format("%s-codebuild", local.name)
  tags = merge(local.default-tags, var.tags)
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = [format("codebuild.%s", module.aws.partition.dns_suffix)]
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_policy" "cb" {
  name        = join("-", [local.name, "codebuild"])
  description = format("Allow access to ECR and S3 for build process")
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Effect   = "Allow"
        Resource = [format("arn:%s:logs:*:*:*", module.aws.partition.partition)]
      },
      {
        Action = [
          "ecr:GetAuthorizationToken",
          "ssm:GetParameters",
        ]
        Effect   = "Allow"
        Resource = ["*"]
      },
      {
        "Action" = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeDhcpOptions",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeVpcs"
        ],
        "Effect"   = "Allow",
        "Resource" = ["*"]
      },
      {
        "Action" = [
          "ec2:CreateNetworkInterfacePermission"
        ],
        "Effect" = "Allow",
        Resource = [format("arn:%s:ec2:%s:%s:network-interface/*",
          module.aws.partition.partition,
          module.aws.region.name,
          module.aws.caller.account_id,
        )]
        "Condition" = {
          "StringEquals" = {
            "ec2:AuthorizedService" = "codebuild.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cb" {
  policy_arn = aws_iam_policy.cb.arn
  role       = aws_iam_role.cb.name
}

resource "aws_iam_role_policy_attachment" "extra" {
  for_each   = { for key, val in var.policy_arns : key => val }
  policy_arn = each.value
  role       = aws_iam_role.cb.name
}
