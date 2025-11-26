output "aws_instance_ip" {
  value = aws_instance.tomcat.public_ip
}

output "pem_file" {
   value = local_file.tomcat_private_key.filename 
}