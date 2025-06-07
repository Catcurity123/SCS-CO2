output "ec2_information" {
  value = {
    ec2_pub_ip      = aws_instance.example_web.public_ip
    ec2_instance_id = aws_instance.example_web.id
    ec2_ami         = data.aws_ami.amazon_linux_2.id
  }
}
