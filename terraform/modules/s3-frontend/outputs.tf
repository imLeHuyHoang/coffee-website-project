output "bucket_name" {
  description = "Ten cua S3 bucket"
  value       = aws_s3_bucket.frontend.id
}

output "bucket_arn" {
  description = "ARN cua S3 bucket"
  value       = aws_s3_bucket.frontend.arn
}

output "website_endpoint" {
  description = "URL website (HTTP) - dung de truy cap truc tiep"
  value       = aws_s3_bucket_website_configuration.frontend.website_endpoint
}

output "website_url" {
  description = "Full URL website voi http://"
  value       = "http://${aws_s3_bucket_website_configuration.frontend.website_endpoint}"
}

output "bucket_regional_domain" {
  description = "Regional domain name (dung cho CloudFront origin)"
  value       = aws_s3_bucket.frontend.bucket_regional_domain_name
}
