resource "aws_vpc" "drupa_vpc" {
  cidr_block = var.cidr
}

resource "aws_subnet" "sub1" {
  vpc_id                  = aws_vpc.drupa_vpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "drupal-sub"
  }
}
resource "aws_subnet" "sub2" {
  vpc_id                  = aws_vpc.drupa_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "drupal-sub2"
  }
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.drupa_vpc.id

  tags = {
    Name = "igw"
  }
}
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.drupa_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}
resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.rt.id
}
resource "aws_route_table_association" "rta2" {
  subnet_id      = aws_subnet.sub2.id
  route_table_id = aws_route_table.rt.id
}
resource "aws_security_group" "websg" {
  name   = "drupal-sg"
  vpc_id = aws_vpc.drupa_vpc.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow access to Prometheus UI
  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Change to restrict access
  }

  # Allow access to Grafana UI
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Change to restrict access
  }

  # Allow Prometheus to scrape Node Exporter metrics from servers
  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Web-sg"
  }
}

resource "aws_instance" "drupa_server_1" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.websg.id]
  subnet_id              = aws_subnet.sub1.id
  key_name               = var.key_name
}
resource "aws_instance" "drupa_server_2" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.websg.id]
  subnet_id              = aws_subnet.sub2.id
  key_name               = var.key_name
}
resource "aws_lb" "myalb" {
  name               = "myalb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.websg.id]
  subnets            = [aws_subnet.sub1.id, aws_subnet.sub2.id]

  tags = {
    name = "drupal-web"
  }
}
resource "aws_lb_target_group" "tg" {
  name     = "drupal-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.drupa_vpc.id

  health_check {
    path = "/"
    port = "traffic-port"
  }
}
resource "aws_lb_target_group_attachment" "attach" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.drupa_server_1.id
  port             = 80
}
resource "aws_lb_target_group_attachment" "attach1" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.drupa_server_2.id
  port             = 80
}
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.myalb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }

}

# RDS Subnet Group (Uses Public Subnets)
resource "aws_db_subnet_group" "public_db_subnet_group" {
  name       = "public-db-subnet-group"
  subnet_ids = [aws_subnet.sub1.id, aws_subnet.sub2.id]

  tags = {
    Name = "Public DB Subnet Group"
  }
}


# RDS Database Instance
resource "aws_db_instance" "mysql" {
  allocated_storage      = 20
  engine                 = "mysql"
  instance_class         = "db.t3.micro"
  db_name                = var.db_name
  username               = var.db_user
  password               = var.db_password
  publicly_accessible    = false # Secure RDS
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.public_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
}

# Security Group for RDS allowing MySQL access
resource "aws_security_group" "rds_sg" {
  vpc_id = aws_vpc.drupa_vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.websg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "loadbalancedns" {
  value = aws_lb.myalb.dns_name
}

output "db_endpoint" {
  value = aws_db_instance.mysql.endpoint
}

