output "ec2_information" {
  value = {
    ec2_pub_ip      = aws_instance.example_web.public_ip
    ec2_instance_id = aws_instance.example_web.id
    ec2_ami         = data.aws_ami.amazon_linux_2.id
  }
}

output "instance_public_url" {
  description = "URL to view the instance metadata web page."
  value       = "http://${aws_instance.example_web.public_ip}"
}

output "ssh_command" {
  description = "Command to SSH into the instance."
  value       = "ssh -i ${local_file.private_key_pem.filename} ec2-user@${aws_instance.example_web.public_ip}"
}