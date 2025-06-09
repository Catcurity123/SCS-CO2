# --- Outputs for the PRIVATE Web Server ---

output "private_ec2_information" {
  description = "Information about the EC2 instance in the private subnet."
  value = {
    # The private IP address of the instance.
    ec2_private_ip = aws_instance.private_web_server.private_ip

    # The ID of the instance.
    ec2_instance_id = aws_instance.private_web_server.id

    # The AMI used for the instance.
    ec2_ami = data.aws_ami.amazon_linux_2.id
  }
}

# --- Outputs for the PUBLIC Bastion Host ---

output "bastion_public_ip" {
  description = "Public IP address of the Bastion Host."
  value       = aws_instance.bastion_host.public_ip
}

output "ssh_to_bastion_command" {
  description = "Command to SSH into the Bastion Host."
  value       = "ssh -i ${local_file.private_key_pem.filename} ec2-user@${aws_instance.bastion_host.public_ip}"
}

# --- Helpful command for the next step ---

output "ssh_from_bastion_to_private_command" {
  description = "Run this command FROM the bastion host to connect to the private server."
  value       = "ssh ec2-user@${aws_instance.private_web_server.private_ip}"
}

# eval $(ssh-agent -s)
# ssh-add {key}
# ssh -A -i {key} {dns}