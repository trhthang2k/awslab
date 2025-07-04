# S3 Bucket to store user-uploaded images
resource "aws_s3_bucket" "user_images" {
  bucket        = "${var.project_name}-user-images"
  force_destroy = false  # Prevent accidental deletion if bucket is not empty

  tags = {
    Name        = "${var.project_name}-user-images"
    Environment = "production"
  }
}

# Block some public access settings (ACLs), but allow bucket policy to manage access
resource "aws_s3_bucket_public_access_block" "block_all" {
  bucket = aws_s3_bucket.user_images.id

  block_public_acls       = true    # Ignore public ACLs
  block_public_policy     = false   # Allow usage of bucket policy (see below)
  ignore_public_acls      = true
  restrict_public_buckets = false   # Do not restrict public access if policy allows it
}

# Enable versioning to track changes to objects over time
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.user_images.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption (SSE) using AES256 (Amazon-managed encryption)
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.user_images.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Bucket policy to allow public read access (GET) to all objects in the bucket
resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.user_images.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"  # Allow all users (public access)
        Action    = "s3:GetObject"  # Only allow read/download
        Resource  = "${aws_s3_bucket.user_images.arn}/*"  # Apply to all objects in the bucket
      }
    ]
  })
}
