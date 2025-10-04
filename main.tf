#vpc creation
resource "aws_vpc" "my-vpc" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"

  tags = {
    Name = "my-vpc"
  }
}

#public subnets
resource "aws_subnet" "public-subnet1" {
  vpc_id     = aws_vpc.my-vpc.id
  cidr_block = var.public_subnet1_cidr
  availability_zone = var.az1
  map_public_ip_on_launch = true

  tags = {
    Name = "public-web-sub-az1"
  }
}

resource "aws_subnet" "public-subnet2" {
  vpc_id     = aws_vpc.my-vpc.id
  cidr_block = var.public_subnet2_cidr
  availability_zone = var.az2
  map_public_ip_on_launch = true

  tags = {
    Name = "public-web-sub-az2"
  }
}

#private subnets
resource "aws_subnet" "app-private-subnet1" {
  vpc_id     = aws_vpc.my-vpc.id
  cidr_block = var.app_private_subnet1_cidr
  availability_zone = var.az1

  tags = {
    Name = "private-app-sub-az1"
  }
}

resource "aws_subnet" "app-private-subnet2" {
  vpc_id     = aws_vpc.my-vpc.id
  cidr_block = var.app_private_subnet2_cidr
  availability_zone = var.az2

  tags = {
    Name = "private-app-sub-az2"
  }
}

resource "aws_subnet" "db-private-subnet1" {
  vpc_id     = aws_vpc.my-vpc.id
  cidr_block = var.db_private_subnet1_cidr
  availability_zone = var.az1

  tags = {
    Name = "private-db-sub-az1"
  }
}

resource "aws_subnet" "db-private-subnet2" {
  vpc_id     = aws_vpc.my-vpc.id
  cidr_block = var.db_private_subnet2_cidr
  availability_zone = var.az2

  tags = {
    Name = "private-db-sub-az2"
  }
}

#internet-gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.my-vpc.id

  tags = {
    Name = "my-ig"
  }
}

#elastic-ip for nat-gatway
resource "aws_eip" "eip1" {
  domain   = "vpc"
}
resource "aws_eip" "eip2" {
  instance = aws_instance.web.id
  domain   = "vpc"
}

#nat-gatway
resource "aws_nat_gateway" "ng-az1" {
  allocation_id = aws_eip.eip1.id
  subnet_id     = aws_subnet.public-subnet1.id

  tags = {
    Name = "ng-az1"
  }
}

resource "aws_nat_gateway" "ng-az2" {
  allocation_id = aws_eip.eip2.id
  subnet_id     = aws_subnet.public-subnet2.id

  tags = {
    Name = "ng-az1"
  }

  depends_on = [ aws_internet_gateway.gw ]
}

#cration