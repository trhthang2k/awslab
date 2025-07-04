# IAM Role for EC2 – allows EC2 to assume the role and access AWS services
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role"

  # Trust relationship policy that allows EC2 to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# IAM Policy attached to the EC2 role – grants permissions to access S3 and RDS
resource "aws_iam_role_policy" "ec2_policy" {
  name = "${var.project_name}-ec2-policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",     # Allow EC2 to download files from S3
          "s3:PutObject"      # Allow EC2 to upload files to S3
        ]
        Resource = "arn:aws:s3:::${var.s3_bucket_name}/*"  # Only allow access to specific bucket
      },
      {
        Effect = "Allow"
        Action = [
          "rds:DescribeDBInstances",  # View details about RDS instances
          "rds:Connect"               # Connect to RDS (if applicable)
        ]
        Resource = "*"  # Applies to all RDS resources (can be restricted further)
      }
    ]
  })
}

# Instance Profile – allows EC2 instance to use the IAM role
resource "aws_iam_instance_profile" "ec2_profile" {
  name = var.instance_profile_name
  role = aws_iam_role.ec2_role.name
}
