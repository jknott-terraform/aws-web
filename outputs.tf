output "elb_address" {
  value = aws_elb.web.dns_name
}

output "addresses" {
  value = aws_instance.web[*].public_ip
}


