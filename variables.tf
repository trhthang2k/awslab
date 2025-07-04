variable "project_name" {
  description = "Project prefix"
  type        = string
  default     = "hello-world"
}

variable "aws_region" {
  description = "AWS region to deploy"
  type        = string
  default     = "ap-northeast-2"
}

variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
  default     = "ami-0662f4965dfc70aca"
}

variable "docker_image" {
  description = "Docker image name to run"
  type        = string
  default     = "trhthang/homework:latest"
}

variable "instance_profile_name" {
  description = "IAM instance profile name"
  type        = string
  default     = "hello-world-ec2-instance-profile"
}

variable "s3_bucket_name" {
  description = "S3 bucket name EC2 instances can access"
  type        = string
  default     = "hello-world-user-images"
}

variable "key_name" {
  description = "The name of the SSH key pair to use for EC2"
  type        = string
  default     = "test"
}
