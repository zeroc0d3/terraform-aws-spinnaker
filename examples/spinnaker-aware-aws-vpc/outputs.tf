output "vpc" {
  description = "The attributes of the secure vpc"
  value       = module.spinnaker-aware-aws-vpc.vpc
}

output "vpce" {
  description = "The attributes of VPC endpoints"
  value       = module.spinnaker-aware-aws-vpc.vpce
}

output "subnets" {
  description = "The map of subnet IDs"
  value       = module.spinnaker-aware-aws-vpc.subnets
}

output "route_tables" {
  description = "The map of route table IDs"
  value       = module.spinnaker-aware-aws-vpc.route_tables
}

output "vgw" {
  description = "The attributes of VGW"
  value       = module.spinnaker-aware-aws-vpc.vgw
}
