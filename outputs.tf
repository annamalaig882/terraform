output "vpc_id" {
  value = aws_vpc.laza_vpc.id
}

output "web_public_ip" {
  value = aws_instance.web.public_ip
}

