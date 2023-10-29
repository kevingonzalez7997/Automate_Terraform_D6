#####################################################################
provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region = "us-west-1"
}
#########################VPC#########################################
resource "aws_vpc" "D6_vpc_US_west" {
  cidr_block       = "10.0.0.0/16"
  tags = {
    Name = "D6_vpc_US_west"
  }
}
#######################SUBNET##########################################
resource "aws_subnet" "public_1" {
    cidr_block = "10.0.1.0/24"
    vpc_id = aws_vpc.D6_vpc_US_west.id
    availability_zone = "us-west-1a"
    map_public_ip_on_launch = true  
    tags = {
    Name = "PublicSubnet_West1"
 }
    
}

resource "aws_subnet" "public_2" {
    cidr_block = "10.0.2.0/24"
    vpc_id = aws_vpc.D6_vpc_US_west.id
    availability_zone = "us-west-1c"
    map_public_ip_on_launch = true  
    tags = {
    Name = "PublicSubnet_West2"
 }
    
}
####################SECURITY_GROUP#######################################
resource "aws_security_group" "pub_sercurity_west" {
  name ="app_and_ssh"
  description = "pub_sercurity_west"
  vpc_id = aws_vpc.D6_vpc_US_west.id
  
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
  vpc_security_group_ids = [aws_security_group.pub_sercurity_west.id]
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
  vpc_security_group_ids = [aws_security_group.pub_sercurity_west.id]
  key_name = "D6keyWest"
  user_data = "${file("appsetup.sh")}"

  tags = {
    Name = "WESTBannkApp2"
  }
}
#######################IGW##################################################################
resource "aws_internet_gateway" "gw_west" {
  vpc_id = aws_vpc.D6_vpc_US_west.id

  tags = {
    Name = "gw_d6_west"
  }
}

##############################################################################################
resource "aws_default_route_table" "routed6_west" {
  default_route_table_id = aws_vpc.D6_vpc_US_west.default_route_table_id
   route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw_west.id
  }
}

######################### TARGET GROUP CREATION ######################################
## Create a target group for the load balancer to use
## port 8000 is used for our application 
resource "aws_lb_target_group" "app_backups_ec2_west" {
  name = "AppBackupsEC2West"
  port = 8000
  protocol = "HTTP"
  vpc_id = aws_vpc.D6_vpc_US_west.id
}
#################### EC2 ATTACHMENT TO TARGET GROUP ###########################################
## Once the target group resource has been created
## attach each agent ec2 -> target group
#AmazonResourceName
resource "aws_lb_target_group_attachment" "register_target_1_west" {
  target_group_arn = aws_lb_target_group.app_backups_ec2_west.arn
  target_id = aws_instance.bankapp.id
  port = 8000
}

resource "aws_lb_target_group_attachment" "register_target_2_west" {
  target_group_arn = aws_lb_target_group.app_backups_ec2_west.arn
  target_id = aws_instance.bankapp2.id
  port = 8000
}


###################### LOADBALANCER  ###################################################
resource "aws_lb" "my_load_balancer" {
  name               = "d6LoadBalanceWest"
  internal           = false # Set to true for internal ALB
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load_balancer_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}


############################# LISTNER ###########################################
#Each load balancer needs a listener to accept incoming requests
resource "aws_lb_listener" "traffichandler" {
  load_balancer_arn = aws_lb.my_load_balancer.arn
  port              = "80"
  protocol          = "HTTP"
 default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_backups_ec2_west.arn
  }
}

###############################LB SECURITY GROUP###############################
resource "aws_security_group" "load_balancer_sg" {
  name        = "d6Wesr-Load-balancer-sg"
  description = "Security group for the load balancer"
  vpc_id      = aws_vpc.D6_vpc_US_west.id

# Since the application is accessed through 8000 
# The Load balancer needs to be able to accept traffic from that port 
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}
