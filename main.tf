#####################################
# PROVIDER
#####################################

provider "aws" {
  region = var.aws_region
}

#####################################
# VPC
#####################################

resource "aws_vpc" "techcorp_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "techcorp-vpc"
  }
}

#####################################
# INTERNET GATEWAY
#####################################

resource "aws_internet_gateway" "techcorp_igw" {
  vpc_id = aws_vpc.techcorp_vpc.id

  tags = {
    Name = "techcorp-igw"
  }
}

#####################################
# PUBLIC SUBNETS (MULTI-AZ)
#####################################

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.techcorp_vpc.id
  cidr_block             = "10.0.1.0/24"
  availability_zone      = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.techcorp_vpc.id
  cidr_block             = "10.0.2.0/24"
  availability_zone      = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-2"
  }
}

#####################################
# PRIVATE SUBNETS
#####################################

resource "aws_subnet" "private_1" {
  vpc_id             = aws_vpc.techcorp_vpc.id
  cidr_block         = "10.0.3.0/24"
  availability_zone  = "us-east-1a"

  tags = {
    Name = "private-subnet-1"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id             = aws_vpc.techcorp_vpc.id
  cidr_block         = "10.0.4.0/24"
  availability_zone  = "us-east-1b"

  tags = {
    Name = "private-subnet-2"
  }
}

#####################################
# NAT GATEWAYS (HA)
#####################################

resource "aws_eip" "nat_1" {
  domain = "vpc"
}

resource "aws_eip" "nat_2" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat_1" {
  allocation_id = aws_eip.nat_1.id
  subnet_id     = aws_subnet.public_1.id

  tags = {
    Name = "nat-1"
  }
}

resource "aws_nat_gateway" "nat_2" {
  allocation_id = aws_eip.nat_2.id
  subnet_id     = aws_subnet.public_2.id

  tags = {
    Name = "nat-2"
  }
}

#####################################
# ROUTE TABLES
#####################################

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.techcorp_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.techcorp_igw.id
  }
}

resource "aws_route_table" "private_rt_1" {
  vpc_id = aws_vpc.techcorp_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_1.id
  }
}

resource "aws_route_table" "private_rt_2" {
  vpc_id = aws_vpc.techcorp_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_2.id
  }
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_rt_1.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private_rt_2.id
}

#####################################
# SECURITY GROUPS
#####################################

resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.techcorp_vpc.id
  name   = "alb-sg"
}

resource "aws_security_group" "web_sg" {
  vpc_id = aws_vpc.techcorp_vpc.id
  name   = "web-sg"
}

resource "aws_security_group" "db_sg" {
  vpc_id = aws_vpc.techcorp_vpc.id
  name   = "db-sg"
}

resource "aws_security_group" "bastion_sg" {
  vpc_id = aws_vpc.techcorp_vpc.id
  name   = "bastion-sg"
}

#####################################
# ALB SG RULES
#####################################

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_out" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

#####################################
# WEB SG (ONLY FROM ALB)
#####################################

resource "aws_vpc_security_group_ingress_rule" "web_http_from_alb" {
  security_group_id            = aws_security_group.web_sg.id
  referenced_security_group_id = aws_security_group.alb_sg.id

  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "web_ssh_from_bastion" {
  security_group_id            = aws_security_group.web_sg.id
  referenced_security_group_id = aws_security_group.bastion_sg.id

  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "web_out" {
  security_group_id = aws_security_group.web_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

#####################################
# DB SG (ONLY FROM WEB)
#####################################

resource "aws_vpc_security_group_ingress_rule" "db_from_web" {
  security_group_id            = aws_security_group.db_sg.id
  referenced_security_group_id = aws_security_group.web_sg.id

  from_port   = 5432
  to_port     = 5432
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "db_ssh_from_bastion" {
  security_group_id            = aws_security_group.db_sg.id
  referenced_security_group_id = aws_security_group.bastion_sg.id

  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "db_out" {
  security_group_id = aws_security_group.db_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

#####################################
# BASTION SG
#####################################

resource "aws_vpc_security_group_ingress_rule" "bastion_ssh" {
  security_group_id = aws_security_group.bastion_sg.id
  cidr_ipv4         = var.ip_address
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "bastion_out" {
  security_group_id = aws_security_group.bastion_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

#####################################
# EC2 INSTANCES
#####################################

resource "aws_instance" "bastion" {
  ami                         = var.ami
  instance_type               = var.bastion_instance_type
  subnet_id                  = aws_subnet.public_1.id
  key_name                  = var.key_pair_name
  vpc_security_group_ids     = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "bastion"
  }
}
resource "aws_eip" "bastion_eip" {
  domain = "vpc"
}
resource "aws_eip_association" "bastion_assoc" {
  instance_id   = aws_instance.bastion.id
  allocation_id = aws_eip.bastion_eip.id
}

resource "aws_instance" "web_1" {
  ami                     = var.ami
  instance_type           = var.web_server_instance_type
  subnet_id              = aws_subnet.private_1.id
  key_name              = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  user_data             = file("${path.module}/user_data/web_server_setup.sh")

  tags = {
    Name = "web-1"
  }
}

resource "aws_instance" "web_2" {
  ami                     = var.ami
  instance_type           = var.web_server_instance_type
  subnet_id              = aws_subnet.private_2.id
  key_name              = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  user_data             = file("${path.module}/user_data/web_server_setup.sh")

  tags = {
    Name = "web-2"
  }
}

resource "aws_instance" "db" {
  ami                     = var.ami
  instance_type           = var.db_instance_type
  subnet_id              = aws_subnet.private_1.id
  key_name              = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  user_data             = file("${path.module}/user_data/db_server_setup.sh")

  tags = {
    Name = "db"
  }
}

#####################################
# ALB
#####################################

resource "aws_lb" "app_alb" {
  name               = "techcorp-alb"
  load_balancer_type = "application"

  subnets = [
    aws_subnet.public_1.id,
    aws_subnet.public_2.id
  ]

  security_groups = [aws_security_group.alb_sg.id]
}

resource "aws_lb_target_group" "tg" {
  name     = "web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.techcorp_vpc.id

health_check {
  path                = "/index.html"
  matcher             = "200"
  interval            = 30
  timeout             = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2
}
}

resource "aws_lb_target_group_attachment" "t1" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.web_1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "t2" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.web_2.id
  port             = 80
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}