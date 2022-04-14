output "Public-IP-Webserver" {
  value = aws_instance.projvpc-web.public_ip
}
output "Private-IP-Webserver" {
  value = aws_instance.projvpc-web.private_ip
}
output "VPC-ID" {
  value = aws_vpc.proj-vpc.id
}