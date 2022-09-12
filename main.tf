terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  access_key = $$$
  secret_key = $$$
  region = "us-east-1"
}


#Create the VPC
 resource "aws_vpc" "Main" {                # Creating VPC here
   cidr_block       = var.main_vpc_cidr     
   instance_tenancy = "default"
   tags = { Name= "vpc_1" }
 }
 #Create Internet Gateway and attach it to VPC
 resource "aws_internet_gateway" "IGW" {    
    vpc_id =  aws_vpc.Main.id               
 }

 #########################

 #Create a Public Subnets
 resource "aws_subnet" "public_subnet1" {    # Creating Public Subnet1
   vpc_id =  aws_vpc.Main.id
   cidr_block = "${var.public_subnet1}"  # CIDR block of public subnet1
   availability_zone = "us-east-1e" 
   tags = { Name = "public_subnet1"}   
 }
resource "aws_subnet" "public_subnet2" {    # Creating Public Subnet2
   vpc_id =  aws_vpc.Main.id
   cidr_block = "${var.public_subnet2}"     # CIDR block of public subnet2
   availability_zone = "us-east-1d"         
   tags = { Name = "public_subnet2"}
 }

############################

 #Create a Private Subnets                   
 resource "aws_subnet" "private_subnet1" {  #creating Private Subnet2
   vpc_id =  aws_vpc.Main.id
   cidr_block = "${var.private_subnet1}"    # CIDR block of private subnet1
   tags = { Name = "private_subnet1"}         
 }
#Create a Private Subnet                   # Creating Private Subnet2
 resource "aws_subnet" "private_subnet2" {
   vpc_id =  aws_vpc.Main.id
   cidr_block = "${var.private_subnet2}"      # CIDR block of private subnet2
   tags = { Name = "private_subnet2"}
 }

##############################

 #Route table for Public Subnet1
 resource "aws_route_table" "PublicRT1" {    # Creating RT for Public Subnet1
    vpc_id =  aws_vpc.Main.id
         route {
    cidr_block = "0.0.0.0/0"               
    gateway_id = aws_internet_gateway.IGW.id
     }
  tags = {Name= "route_table_for_publlic_subnet1"}
 }

#Route table for Public Subnet2
 resource "aws_route_table" "PublicRT2" {    # Creating RT for Public Subnet2
    vpc_id =  aws_vpc.Main.id
         route {
    cidr_block = "0.0.0.0/0"               
    gateway_id = aws_internet_gateway.IGW.id
     }
  tags = {Name= "route_table_for_publlic_subnet2"}
 }


 #Route table for Private Subnet1
 resource "aws_route_table" "PrivateRT1" {    # Creating RT for Private Subnet1
   vpc_id = aws_vpc.Main.id
   route {
   cidr_block = "0.0.0.0/0"             
   nat_gateway_id = aws_nat_gateway.NATgw.id
   }
  tags = {Name= "route_table_for_private_subnet1"}
 }
 #Route table for Private Subnet2
 resource "aws_route_table" "PrivateRT2" {    # Creating RT for Private Subnet2
   vpc_id = aws_vpc.Main.id
   route {
   cidr_block = "0.0.0.0/0"             
   nat_gateway_id = aws_nat_gateway.NATgw.id
   }
  tags = {Name= "route_table_for_private_subnet1"}
 }
###############################

 #Route table Association with Public Subnet1
 resource "aws_route_table_association" "PublicRT1association" {
    subnet_id = aws_subnet.public_subnet1.id
    route_table_id = aws_route_table.PublicRT1.id
 }

 #Route table Association with Public Subnet2
 resource "aws_route_table_association" "PublicRT2association" {
    subnet_id = aws_subnet.public_subnet2.id
    route_table_id = aws_route_table.PublicRT2.id
 }
 #Route table Association with Private Subnet1
 resource "aws_route_table_association" "PrivateRT1association" {
    subnet_id = aws_subnet.private_subnet1.id
    route_table_id = aws_route_table.PrivateRT1.id
 }

#Route table Association with Private Subnet2
 resource "aws_route_table_association" "PrivateRT2association" {
    subnet_id = aws_subnet.private_subnet2.id
    route_table_id = aws_route_table.PrivateRT2.id
 }


 resource "aws_eip" "nateIP" {
   vpc   = true
 }
 #Creating the NAT Gateway 
 resource "aws_nat_gateway" "NATgw" {
   allocation_id = aws_eip.nateIP.id
   subnet_id = aws_subnet.public_subnet1.id
 }

 ################
 #Create security group that allows port 80 and 443
 resource "aws_security_group" "elb" {
  name        = "allow 80 AND 443"
  description = "Allow 80 AND 443"
  vpc_id      = aws_vpc.Main.id

  ingress {
    description      = "https from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
 ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
 }
#################################
#Create an ELB 
 resource "aws_elb" "web" {
  name = "terraform-elb"
  subnets = [aws_subnet.public_subnet1.id, aws_subnet.public_subnet2.id]
  security_groups = [aws_security_group.elb.id]
 

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
  listener {
    instance_port     = 443
    instance_protocol = "tcp"
    lb_port           = 443
    lb_protocol       = "tcp"
  }
}

####################
#Create a route53 private Hosted zone.
resource "aws_route53_zone" "private" {
  name = "test.com"

  vpc {
    vpc_id = aws_vpc.Main.id
  }
}
#create record point to ELB 
resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "elb-alias"
  type    = "A"

  alias {
    name                   = aws_elb.web.dns_name
    zone_id                = aws_elb.web.zone_id
    evaluate_target_health = true
  }
}