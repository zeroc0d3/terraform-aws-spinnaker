aws_region      = "ap-northeast-2"
azs             = ["ap-northeast-2a", "ap-northeast-2c", "ap-northeast-2d"]
use_default_vpc = true
name            = "ecs-tc2-mixed"
tags = {
  env                   = "dev"
  test                  = "tc2"
  default_vpc           = "true"
  termination_protected = "false"
  node_groups_type      = "mixed"
}
container_insights_enabled = false
termination_protection     = false
node_groups = [
  {
    name          = "mixed"
    min_size      = 1
    max_size      = 3
    desired_size  = 2
    instance_type = "t3.medium"
    instances_distribution = {
      on_demand_percentage_above_base_capacity = 50
      spot_allocation_strategy                 = "capacity-optimized"
    }
    instances_override = [
      {
        instance_type     = "t3.small"
        weighted_capacity = 2
      },
      {
        instance_type     = "t3.large"
        weighted_capacity = 1
      }
    ]
  },
  {
    name          = "default"
    min_size      = 1
    max_size      = 3
    desired_size  = 1
    instance_type = "t3.large"
  }
]
