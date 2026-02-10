output "role_arn" {
  description = "ARN cua Lambda execution role"
  value       = aws_iam_role.lambda_exec.arn
}

output "role_name" {
  description = "Ten cua Lambda execution role"
  value       = aws_iam_role.lambda_exec.name
}

output "policy_arn" {
  description = "ARN cua Lambda policy"
  value       = aws_iam_policy.lambda_policy.arn
}
