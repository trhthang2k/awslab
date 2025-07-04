# DB Subnet Group – defines which subnets the RDS instance can be placed in
# These are private subnets across multiple availability zones
resource "aws_db_subnet_group" "rds_subnets" {
  name       = "${var.project_name}-rds-subnet-group"
  subnet_ids = [
    aws_subnet.private_subnet_1.id,
    aws_subnet.private_subnet_2.id,
    aws_subnet.private_subnet_3.id,
  ]

  tags = {
    Name = "${var.project_name}-rds-subnet-group"
  }
}

# Security Group for RDS – allows inbound MySQL traffic on port 3306
# Currently allows access from anywhere (0.0.0.0/0); should be restricted in production
resource "aws_security_group" "rds_sg" {
  name        = "${var.project_name}-rds-sg"
  description = "Allow internal access to RDS"
  vpc_id      = aws_vpc.hello_world_vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow MySQL access from anywhere (use caution!)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # Allow all outbound traffic
  }

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}

# RDS Instance
resource "aws_db_instance" "demo" {
  identifier              = "${var.project_name}-demo-db"
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"  
  allocated_storage       = 20
  storage_type            = "gp2"
  username                = ""
  password                = ""  

  db_subnet_group_name    = aws_db_subnet_group.rds_subnets.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]

  multi_az                = false         
  publicly_accessible     = true          
  skip_final_snapshot     = true         

  tags = {
    Name        = "${var.project_name}-demo-db"
    Environment = "test"
  }
}
