output "vpc_information" {
  value = {
    vpc_cidr              = aws_vpc.lab02_vpc.cidr_block
    public_subnet_cidr    = aws_subnet.lab02_public_subnet.cidr_block
    private_subnet_cidr   = aws_subnet.lab02_private_subnet.cidr_block
    private_subnet_2_cidr = aws_subnet.lab02_private_subnet_2.cidr_block
    gateway_public_ip     = aws_eip.lab02_nat_ip.public_ip
  }
}

output "rds_credentials" {
  sensitive = true # ← marks the entire output block as sensitive
  value = {
    username = aws_db_instance.lab02_rds.username
    password = aws_db_instance.lab02_rds.password
  }
}

/* terraform apply

terraform output -json rds_information

terraform output -json rds_information | jq '.password' */

output "rds_information" {
  value = {
    private_ip  = aws_db_instance.lab02_rds.address
    endpoint    = aws_db_instance.lab02_rds.endpoint
    domain_fqdn = aws_db_instance.lab02_rds.hosted_zone_id
    id          = aws_db_instance.lab02_rds.id
    status      = aws_db_instance.lab02_rds.status
  }
}

output "bastion_ec2_information" {
  description = "Information about the EC2 instance in the private subnet."
  value = {
    # The private IP address of the instance.
    ec2_bastion_ip = aws_instance.lab02_bastion_host.public_ip
    # The ID of the instance.
    ec2_bastion_id = aws_instance.lab02_bastion_host.id
    # The AMI used for the instance.
    ec2_ami = data.aws_ami.amazon_linux_2.id
  }
}
