output "server_ip" {
  value = aws_instance.server.public_ip
  
}
output "instance_id" {
  value = aws_instance.server.id
}