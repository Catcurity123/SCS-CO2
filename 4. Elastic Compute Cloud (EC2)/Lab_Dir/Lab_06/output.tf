output "vpc_basic_info" {
  description = "Basic information about created vpc"
  value = {
    main_vpc_cidr  = aws_vpc.main_vpc.cidr_block
    public_subnet  = aws_subnet.public1.cidr_block
    private_subnet = aws_subnet.private1.cidr_block
  }
}

output "ec2_basic_info" {
  description = "Basic information about EC2"
  value = {
    ec2_ami           = aws_instance.test_host.ami
    ec2_instance_type = aws_instance.test_host.instance_type
    ec2_private_ip    = aws_instance.test_host.private_ip
    ec2_public_ip     = aws_instance.test_host.public_ip
    ec2_sg            = aws_instance.test_host.vpc_security_group_ids
    ec2_key           = aws_instance.test_host.key_name
  }

}

output "command_to_lab" {
  description = "Commands to do lab"
  value       = "ssh -i ${aws_key_pair.generated_key.key_name} ubuntu@${aws_instance.test_host.public_ip}"
}