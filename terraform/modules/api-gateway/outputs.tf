# ==============================================================================
# API Gateway Module Outputs
# ==============================================================================

output "api_id" {
  description = "ID cua REST API"
  value       = aws_api_gateway_rest_api.coffee_api.id
}

output "api_execution_arn" {
  description = "Execution ARN cua API (dung cho Lambda permission source_arn)"
  value       = aws_api_gateway_rest_api.coffee_api.execution_arn
}

output "invoke_url" {
  description = "URL de goi API (vd: https://abc123.execute-api.ap-southeast-1.amazonaws.com/prod)"
  value       = aws_api_gateway_stage.prod.invoke_url
}

output "stage_name" {
  description = "Ten stage dang deploy"
  value       = aws_api_gateway_stage.prod.stage_name
}
