# ==============================================================================
# S3 Images Module Outputs
# ==============================================================================

output "bucket_name" {
  description = "Ten cua S3 images bucket"
  value       = aws_s3_bucket.images.id
}

output "bucket_arn" {
  description = "ARN cua S3 images bucket (dung cho IAM policy)"
  value       = aws_s3_bucket.images.arn
}

output "bucket_regional_domain" {
  description = "Regional domain name (dung cho CloudFront hoac presigned URLs)"
  value       = aws_s3_bucket.images.bucket_regional_domain_name
}
