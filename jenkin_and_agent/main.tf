#####################################################################
provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region = "us-east-1"
}


data "aws_security_group" "existing_sg" {
  id = var.id 
}
##################################I N S T A N C E S#################################################
resource "aws_instance" "jenkins_ec2" {
  ami           = "ami-053b0d53c279acc90"
  instance_type = "t2.medium"
  availability_zone = "us-east-1a" # Specify the desired availability zone
  key_name = "deploy_6"
  vpc_security_group_ids = [data.aws_security_group.existing_sg.id]
  user_data = "${file("jenkins_install.sh")}"
  tags = {
    Name = "jenkins_ec2"
  }

}

resource "aws_instance" "Agent_ec2" {
  ami           = "ami-053b0d53c279acc90"
  instance_type = "t2.medium"
  availability_zone = "us-east-1b" # Specify the desired availability zone
  key_name = "deploy_6"
  vpc_security_group_ids = [data.aws_security_group.existing_sg.id]
  user_data = "${file("terraform.sh")}"
  tags = {
    Name = "Agent_ec2"
  }
}
###############################################################################