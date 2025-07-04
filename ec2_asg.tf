# Security Group cho EC2 instance – chỉ cho phép nhận traffic từ ALB qua cổng 3000
resource "aws_security_group" "ec2_sg" {
  name        = "${var.project_name}-ec2-sg"
  description = "Allow traffic from ALB"
  vpc_id      = aws_vpc.hello_world_vpc.id

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]  # Chỉ ALB mới được phép truy cập
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # Cho phép gửi traffic ra ngoài (internet)
  }

  tags = {
    Name = "${var.project_name}-ec2-sg"
  }
}

# Launch Template định nghĩa cấu hình EC2 instance được sử dụng bởi Auto Scaling Group
resource "aws_launch_template" "app_lt" {
  name_prefix   = "${var.project_name}-lt"
  image_id      = var.ami_id
  instance_type = "t3.micro"
  key_name      = var.key_name  # Dùng để SSH vào instance nếu cần

  iam_instance_profile {
    name = var.instance_profile_name  # Cho phép EC2 gắn IAM role nếu cần
  }

  user_data = base64encode(templatefile("user-data.sh", {
    docker_image = var.docker_image  # Script khởi tạo sẽ chạy container với image này
  }))

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]  # Gắn security group cho instance

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-instance"
    }
  }
}

# Auto Scaling Group để triển khai và quản lý số lượng EC2 instance động
resource "aws_autoscaling_group" "app_asg" {
  name                      = "${var.project_name}-asg"
  max_size                  = 2
  min_size                  = 1
  desired_capacity          = 1  # Khởi tạo mặc định 1 instance
  health_check_type         = "EC2"
  force_delete              = true  # Xóa ASG sẽ tự động xóa instance

  vpc_zone_identifier = [
    aws_subnet.private_subnet_1.id,
    aws_subnet.private_subnet_2.id,
    aws_subnet.private_subnet_3.id,  # EC2 sẽ được đặt trong các subnet private
  ]

  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.app_tg.arn]  # Kết nối với target group của ALB

  tag {
    key                 = "Name"
    value               = "${var.project_name}-asg-instance"
    propagate_at_launch = true  # Gắn tag cho tất cả instance mới tạo
  }
}

# Application Load Balancer (ALB) – nhận lưu lượng từ Internet
resource "aws_lb" "app_alb" {
  name               = "${var.project_name}-alb"
  internal           = false  # Public ALB
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]  # Gắn security group cho ALB

  subnets = [
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id,
    aws_subnet.public_subnet_3.id,  # ALB sẽ nằm trong các subnet public
  ]

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# Security Group cho ALB – cho phép nhận lưu lượng HTTP/HTTPS từ bất kỳ đâu
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg"
  description = "Allow HTTP from anywhere"
  vpc_id      = aws_vpc.hello_world_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Cho phép HTTP từ bất kỳ địa chỉ nào
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Cho phép HTTPS từ bất kỳ địa chỉ nào
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # Cho phép gửi traffic ra ngoài (Internet)
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

# Target Group – chứa các EC2 instance để ALB chuyển hướng lưu lượng đến
resource "aws_lb_target_group" "app_tg" {
  name     = "${var.project_name}-tg"
  port     = 3000  # Cổng của ứng dụng đang chạy
  protocol = "HTTP"
  vpc_id   = aws_vpc.hello_world_vpc.id

  health_check {
    path                = "/"  # Endpoint dùng để kiểm tra tình trạng instance
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Listener trên ALB – lắng nghe lưu lượng HTTPS và chuyển tiếp đến Target Group
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 443
  protocol          = "HTTPS"

  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:ap-northeast-2:968548635475:certificate/056ef2ec-6771-45dd-b846-7a90381716ea"  # Chứng chỉ SSL cho HTTPS

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn  # Chuyển tiếp đến EC2 qua target group
  }
}
