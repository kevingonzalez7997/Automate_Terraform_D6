#####################################################################
provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region = "us-west-1"
}
#########################VPC#########################################
resource "aws_vpc" "deployment6_vpc_US_west" {
  cidr_block       = "10.0.0.0/16"
  tags = {
    Name = "deployment6-vpc-US-west"
  }
}
#######################SUBNET##########################################
resource "aws_subnet" "public_1" {
    cidr_block = "10.0.1.0/24"
    vpc_id = aws_vpc.deployment6_vpc_US_west.id
    availability_zone = "us-west-1a"
    map_public_ip_on_launch = true  
    tags = {
    Name = "PublicSubnet_West1"
 }
    
}

resource "aws_subnet" "public_2" {
    cidr_block = "10.0.2.0/24"
    vpc_id = aws_vpc.deployment6_vpc_US_west.id
    availability_zone = "us-west-1b"
    map_public_ip_on_launch = true  
    tags = {
    Name = "PublicSubnet_West2"
 }
    
}

####################SECURITY_GROUP#######################################
resource "aws_security_group" "pub1_sercurity" {
  name ="app_and_ssh"
  description = "pub1_sercurity"
  vpc_id = aws_vpc.deployment6_vpc_US_west.id
  
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
 
 tags = {
  "Name" : "D6_West_SG"
  "Terraform" : "true"
 }

}

#####################################EC2#################################################
resource "aws_instance" "bankapp" {
  ami           = "ami-0cbd40f694b804622"
  instance_type = "t2.medium"
  subnet_id = aws_subnet.public_1.id
  vpc_security_group_ids = [aws_security_group.pub1_sercurity.id]
  key_name = "D6keyWest"
  user_data = "${file("appsetup.sh")}"
  tags = {
    Name = "WESTBankApp1"
  }
}

resource "aws_instance" "bankapp2" {
  ami           = "ami-0cbd40f694b804622"
  instance_type = "t2.medium"
  subnet_id = aws_subnet.public_2.id
  vpc_security_group_ids = [aws_security_group.pub1_sercurity.id]
  key_name = "D6keyWest"
  user_data = "${file("appsetup.sh")}"

  tags = {
    Name = "WESTBannkApp2"
  }
}
#######################IGW##################################################################
resource "aws_internet_gateway" "gw_west" {
  vpc_id = aws_vpc.deployment6_vpc_US_west.id

  tags = {
    Name = "gw_d6_west"
  }
}

##############################################################################################
resource "aws_default_route_table" "routed6_west" {
  default_route_table_id = aws_vpc.deployment6_vpc_US_west.default_route_table_id
   route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw_west.id
  }
}
