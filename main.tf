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

#cration of route tables 1 for public and 2 for private
resource "aws_route_table" "public-rt"{
  vpc_id = aws_vpc.my-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table_association" "public-sub1-assosiation-rt"{
  subnet_id      = aws_subnet.public-subnet1.id
  route_table_id = aws_route_table.public-rt.id
}

resource "aws_route_table_association" "public-sub2-assosiation-rt"{
  subnet_id      = aws_subnet.public-subnet2.id
  route_table_id = aws_route_table.public-rt.id
}

#private route table and assosiation
resource "aws_route_table" "private-rt1"{
  vpc_id = aws_vpc.my-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ng-az1.id
  }

  tags = {
    Name = "private-rt-az1"
  }
}

resource "aws_route_table_association" "private-sub1-assosiation-rt"{
  subnet_id      = aws_subnet.app-private-subnet1.id
  route_table_id = aws_route_table.private-rt1.id
}

resource "aws_route_table" "private-rt2"{
  vpc_id = aws_vpc.my-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ng-az2.id
  }

  tags = {
    Name = "private-rt-az2"
  }
}

resource "aws_route_table_association" "private-sub2-assosiation-rt"{
  subnet_id      = aws_subnet.app-private-subnet2.id
  route_table_id = aws_route_table.private-rt2.id
}

#security groups in each layer
#internet facing load balancer
resource "aws_security_group" "internet-facing-lb-sg" {
  name        = "Internet-facing-lb-sg"
  description = "Internet facing load balancer security group"
  vpc_id      = aws_vpc.my-vpc.id

  tags = {
    Name = "Internet-facing-lb-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "HTTP" {
  security_group_id = aws_security_group.internet-facing-lb-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "All_Traffic" {
  security_group_id = aws_security_group.internet-facing-lb-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" // semantically equivalent to all ports
}

#web-tier security group
resource "aws_security_group" "web-tier-sg" {
  name        = "Web-Tier-sg"
  description = "Security Group for Web Tier"
  vpc_id      = aws_vpc.my-vpc.id

  tags = {
    Name = "Web-Tier-sg"
  }
}

resource "aws_security_group_rule" "web-tier-sg-ingress-rule1" {
  security_group_id        = aws_security_group.web-tier-sg.id
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.internet-facing-lb-sg.id
}

resource "aws_security_group_rule" "web-tier-sg-ingress-rule2" {
  security_group_id = aws_security_group.web-tier-sg.id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [var.myip]
}

resource "aws_security_group_rule" "web-tier-sg-egress-rule" {
  security_group_id = aws_security_group.web-tier-sg.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

#Internal Load Balancer Securiity Group

resource "aws_security_group" "internal-lb-sg" {
  name        = "Internal-lb-sg"
  description = "Security Group for Internal Load Balancer"
  vpc_id      = aws_vpc.my-vpc.id

  tags = {
    Name = "Internal-lb-sg"
  }
}

resource "aws_security_group_rule" "internal-lb-sg-ingress-rule" {
  security_group_id        = aws_security_group.internal-lb-sg.id
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.web-tier-sg.id
}

resource "aws_security_group_rule" "internal-lb-sg-egress-rule" {
  security_group_id = aws_security_group.internal-lb-sg.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

#Private Instance security group

resource "aws_security_group" "private-instance-sg" {
  name        = "Private-Instance-sg"
  description = "Private Instance security group"
  vpc_id      = aws_vpc.my-vpc.id

  tags = {
    Name = "Private-Instance-sg"
  }
}

resource "aws_security_group_rule" "private-instance-sg-ingress-rule1" {
  security_group_id        = aws_security_group.private-instance-sg.id
  type                     = "ingress"
  from_port                = 4000 // Backend app supoorts port 4000
  to_port                  = 4000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.internal-lb-sg.id
}
resource "aws_security_group_rule" "private-instance-sg-ingress-rule2" {
  security_group_id = aws_security_group.private-instance-sg.id
  type              = "ingress"
  from_port         = 4000 // Backend app supoorts port 4000
  to_port           = 4000
  protocol          = "tcp"
  cidr_blocks       = [var.myip]//Mention your current IP in terraform.tfvars
}

resource "aws_security_group_rule" "private-instance-sg-egress-rule" {
  security_group_id = aws_security_group.private-instance-sg.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}
