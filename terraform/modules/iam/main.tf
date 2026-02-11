# ------------------------------------------------------------------------------
# 1. IAM Role cho Lambda
# ------------------------------------------------------------------------------
# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role
# AWS doc ve Trust Policy:
# https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_principal.html
# ------------------------------------------------------------------------------
resource "aws_iam_role" "lambda_exec" {
  name = var.role_name

  # Trust Policy: Chi cho phep Lambda service assume role nay
  # "Service": "lambda.amazonaws.com" -> chi Lambda functions moi co the dung role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# ------------------------------------------------------------------------------
# 2. IAM Policy - Quyen truy cap cho Lambda
# ------------------------------------------------------------------------------
# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy
# ------------------------------------------------------------------------------
resource "aws_iam_policy" "lambda_policy" {
  name        = var.policy_name
  description = "Permissions for Coffee Shop Lambda functions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # --- DynamoDB permissions ---
      # Cho phep Lambda doc/ghi du lieu trong cac DynamoDB tables
      {
        Sid    = "DynamoDBAccess"
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",    # Tao item moi (tao don hang, dang ky user)
          "dynamodb:GetItem",    # Doc 1 item theo primary key
          "dynamodb:Query",      # Tim kiem theo partition key + dieu kien
          "dynamodb:Scan",       # Doc toan bo table (dung cho get-products)
          "dynamodb:UpdateItem", # Cap nhat 1 item (cap nhat trang thai don hang)
          "dynamodb:DeleteItem"  # Xoa 1 item
        ]
        Resource = [
          "arn:aws:dynamodb:${var.aws_region}:*:table/${var.dynamodb_table_prefix}*",
          "arn:aws:dynamodb:${var.aws_region}:*:table/${var.dynamodb_table_prefix}*/index/*"
        ]
      },

      # --- CloudWatch Logs permissions ---
      # BAT BUOC cho moi Lambda function de ghi execution logs
      # Khong co quyen nay -> Lambda van chay nhung khong co logs de debug
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",  # Tao log group moi (1 lan dau)
          "logs:CreateLogStream", # Tao log stream (moi invocation)
          "logs:PutLogEvents"     # Ghi log entries
        ]
        Resource = "arn:aws:logs:*:*:*"
      },

      # --- S3 permissions ---
      # Cho phep Lambda doc/ghi anh san pham vao S3 bucket
      {
        Sid    = "S3Access"
        Effect = "Allow"
        Action = [
          "s3:PutObject", # Upload anh
          "s3:GetObject"  # Doc anh
        ]
        Resource = "arn:aws:s3:::${var.images_bucket_name}/*"
      },

      # --- SES permissions ---
      # Cho phep Lambda gui email (xac nhan don hang, welcome email)
      {
        Sid    = "SESAccess"
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = "*"
      }
    ]
  })

  tags = var.tags
}

# ------------------------------------------------------------------------------
# 3. Gan Policy vao Role
# ------------------------------------------------------------------------------
# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}
