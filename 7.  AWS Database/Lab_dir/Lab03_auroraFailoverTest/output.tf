output "vpc_information" {
  value = {
    vpc_cidr              = aws_vpc.lab03_vpc.cidr_block
    public_subnet_cidr    = aws_subnet.lab03_public_subnet.cidr_block
    private_subnet_cidr   = aws_subnet.lab03_private_subnet.cidr_block
    private_subnet_2_cidr = aws_subnet.lab03_private_subnet_2.cidr_block
    gateway_public_ip     = aws_eip.lab03_nat_ip.public_ip
  }
}

output "rds_credentials" {
  sensitive = true # ← marks the entire output block as sensitive
  value = {
    username = aws_rds_cluster.lab03_aurora.master_username
    password = aws_rds_cluster.lab03_aurora.master_password
  }
}

/* terraform apply

terraform output -json aurora_information

terraform output -json aurora_information | jq '.endpoint' */

output "aurora_information" {
  value = {
    endpoint           = aws_rds_cluster.lab03_aurora.endpoint
    reader_endpoint    = aws_rds_cluster.lab03_aurora.reader_endpoint
    cluster_identifier = aws_rds_cluster.lab03_aurora.cluster_identifier
  }
}

output "bastion_ec2_information" {
  description = "Information about the EC2 instance in the private subnet."
  value = {
    # The private IP address of the instance.
    ec2_bastion_ip = aws_instance.lab03_bastion_host.public_ip
    # The ID of the instance.
    ec2_bastion_id = aws_instance.lab03_bastion_host.id
    # The AMI used for the instance.
    ec2_ami = data.aws_ami.amazon_linux_2.id
  }
}
