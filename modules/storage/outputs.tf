output "bucket_name" {
  description = "Name of the created S3 bucket"
  value       = aws_s3_bucket.assets_bucket.id
}

output "bucket_arn" {
  description = "ARN of the created S3 bucket"
  value       = aws_s3_bucket.assets_bucket.arn
}

output "bucket_domain_name" {
  description = "Domain name of the created S3 bucket"
  value       = aws_s3_bucket.assets_bucket.bucket_regional_domain_name
}
