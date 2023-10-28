#####################################################################
provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region = "us-east-1"
}
######################### VPC #########################################
resource "aws_vpc" "D6_vpc_us_east" {
  cidr_block       = "10.0.0.0/16"
  tags = {
    Name = "D6_vpc_us_east"
  }
}
####################### SUBNET ##########################################
resource "aws_subnet" "public_subnet1_east" {
    cidr_block = "10.0.1.0/24"
    vpc_id = aws_vpc.D6_vpc_us_east.id
    availability_zone = "us-east-1a"
    map_public_ip_on_launch = true  
}

resource "aws_subnet" "public_subnet2_east" {
    cidr_block = "10.0.2.0/24"
    vpc_id = aws_vpc.D6_vpc_us_east.id
    availability_zone = "us-east-1b"
    map_public_ip_on_launch = true  
}
#################### SECURITY_GROUP ######################################
resource "aws_security_group" "pub1_sercurity" {
  name ="app_and_ssh"
  description = "pub1_sercurity"
  vpc_id = aws_vpc.D6_vpc_us_east.id
  
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 8000
    to_port = 8000
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}
##################################### EC2 #################################################
resource "aws_instance" "bankapp" {
  ami           = "ami-053b0d53c279acc90"
  instance_type = "t2.medium"
  availability_zone = "us-east-1a" 
  subnet_id = aws_subnet.public_subnet1_east.id
  vpc_security_group_ids = [aws_security_group.pub1_sercurity.id]
  key_name = "deploy_6"
  user_data = "${file("appsetup.sh")}"
  tags = {
    Name = "EastBankApp1"
  }
}

resource "aws_instance" "bankapp2" {
  ami           = "ami-053b0d53c279acc90"
  instance_type = "t2.medium"
  availability_zone = "us-east-1b" # Specify the desired availability zone
  subnet_id = aws_subnet.public_subnet2_east.id
  vpc_security_group_ids = [aws_security_group.pub1_sercurity.id]
  key_name = "deploy_6"
  tags = {
    Name = "EastBankApp2"
  }
}
####################### IGW  ##########################################################
resource "aws_internet_gateway" "D6Eastgw" {
  vpc_id = aws_vpc.D6_vpc_us_east.id

  tags = {
    Name = "D6_igw_East"
  }
}
#################################  ROUTE TABLE  #########################################
resource "aws_default_route_table" "D6_route_east" {
  default_route_table_id = aws_vpc.D6_vpc_us_east.default_route_table_id
   route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.D6Eastgw.id
  }
}
