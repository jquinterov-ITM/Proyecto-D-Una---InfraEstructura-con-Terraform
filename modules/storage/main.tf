resource "aws_s3_bucket" "assets_bucket" {
  bucket = "${var.env}-${var.bucket_name}"

  tags = {
    Name        = "${var.env}-assets"
    Environment = var.env
  }
}

resource "aws_s3_bucket_public_access_block" "assets_bucket_pab" {
  bucket = aws_s3_bucket.assets_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "assets_bucket_policy" {
  bucket     = aws_s3_bucket.assets_bucket.id
  depends_on = [aws_s3_bucket_public_access_block.assets_bucket_pab]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.assets_bucket.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_cors_configuration" "assets_cors" {
  bucket = aws_s3_bucket.assets_bucket.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST"]
    allowed_origins = var.cors_allowed_origins
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}
