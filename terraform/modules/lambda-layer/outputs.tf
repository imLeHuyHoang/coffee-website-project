output "layer_arn" {
  description = "ARN cua Lambda Layer (bao gom version) - dung de attach vao Lambda function"
  value       = aws_lambda_layer_version.dependencies.arn
}

output "layer_version" {
  description = "Version number cua Layer"
  value       = aws_lambda_layer_version.dependencies.version
}
