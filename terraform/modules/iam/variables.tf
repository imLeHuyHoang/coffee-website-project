variable "role_name" {
  description = "Ten IAM Role cho Lambda"
  type        = string
  default     = "CoffeeLambdaRole"
}

variable "policy_name" {
  description = "Ten IAM Policy cho Lambda"
  type        = string
  default     = "CoffeeLambdaPolicy"
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
}

variable "images_bucket_name" {
  description = "Ten S3 bucket chua anh san pham"
  type        = string
  default     = "coffee-shop-images"
}

variable "dynamodb_table_prefix" {
  description = "Prefix cho ten cac DynamoDB tables (dung trong IAM policy resource pattern)"
  type        = string
  default     = "Coffee"
}

variable "tags" {
  description = "Tags chung"
  type        = map(string)
  default     = {}
}
