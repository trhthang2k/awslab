# Security Group for EC2 instance – only allow traffic from ALB on port 3000
resource "aws_security_group" "ec2_sg" {
  name        = "${var.project_name}-ec2-sg"
  description = "Allow traffic from ALB"
  vpc_id      = aws_vpc.hello_world_vpc.id

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]  # Only allow traffic from ALB
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # Allow outbound internet access
  }

  tags = {
    Name = "${var.project_name}-ec2-sg"
  }
}

# Launch Template defines EC2 configuration used by Auto Scaling Group
resource "aws_launch_template" "app_lt" {
  name_prefix   = "${var.project_name}-lt"
  image_id      = var.ami_id
  instance_type = "t3.micro"
  key_name      = var.key_name  # SSH key for accessing EC2 if needed

  iam_instance_profile {
    name = var.instance_profile_name  # Attach IAM role to EC2 if needed
  }

  user_data = base64encode(templatefile("user-data.sh", {
    docker_image = var.docker_image  # Startup script to run Docker container with this image
  }))

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]  # Attach EC2 security group

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-instance"
    }
  }
}

# Auto Scaling Group to manage dynamic EC2 instances
resource "aws_autoscaling_group" "app_asg" {
  name                      = "${var.project_name}-asg"
  max_size                  = 2
  min_size                  = 1
  desired_capacity          = 1  # Default to 1 instance
  health_check_type         = "EC2"
  force_delete              = true  # Auto-delete EC2 instances when ASG is removed

  vpc_zone_identifier = [
    aws_subnet.private_subnet_1.id,
    aws_subnet.private_subnet_2.id,
    aws_subnet.private_subnet_3.id,  # EC2 instances will be placed in private subnets
  ]

  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.app_tg.arn]  # Attach to ALB target group

  tag {
    key                 = "Name"
    value               = "${var.project_name}-asg-instance"
    propagate_at_launch = true  # Tag all launched EC2 instances
  }
}

# Application Load Balancer (ALB) – handles external traffic from the Internet
resource "aws_lb" "app_alb" {
  name               = "${var.project_name}-alb"
  internal           = false  # Public ALB
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]  # Attach ALB security group

  subnets = [
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id,
    aws_subnet.public_subnet_3.id,  # ALB will be placed in public subnets
  ]

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# Security Group for ALB – allow incoming HTTP/HTTPS from anywhere
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg"
  description = "Allow HTTP and HTTPS from anywhere"
  vpc_id      = aws_vpc.hello_world_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow HTTP from any IP
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow HTTPS from any IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # Allow outbound internet access
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

# Target Group – defines where ALB forwards traffic
resource "aws_lb_target_group" "app_tg" {
  name     = "${var.project_name}-tg"
  port     = 3000  # Application runs on this port
  protocol = "HTTP"
  vpc_id   = aws_vpc.hello_world_vpc.id

  health_check {
    path                = "/"  # Health check endpoint
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# ALB Listener – listens on HTTPS and forwards to the target group
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 443
  protocol          = "HTTPS"

  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:ap-northeast-2:968548635475:certificate/056ef2ec-6771-45dd-b846-7a90381716ea"  # SSL certificate for HTTPS

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn  # Forward traffic to EC2 via target group
  }
}
