# alb module
output "lb_dns_name" {
  description = "Public DNS name of the load balancer"
  value       = module.alb.this_lb_dns_name
}

output "private_ec2_ids" {
  description = "IDs of EC2 instances"
  value       = aws_instance.linux.*.id
}

output "private_ec2_private_ips" {
  description = "Private IPs of EC2 instances"
  value       = aws_instance.linux.*.private_ip
}

output "public_ec2_ids" {
  description = "IDs of EC2 instances"
  value       = aws_instance.linux_pub.*.id
}
output "public_ec2_private_ips" {
  description = "Private IPs of EC2 instances"
  value       = aws_instance.linux_pub.*.private_ip
}
output "public_ec2_public_ips" {
  description = "Public IPs of EC2 instances"
  value       = aws_instance.linux_pub.*.public_ip
}
