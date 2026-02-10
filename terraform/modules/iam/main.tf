# ==============================================================================
# IAM Module - Lambda Execution Role & Policy
# ==============================================================================
# Doc goc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role
# Doc goc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy
#
# Module nay tao:
#   1. IAM Role: cho phep Lambda service "assume" role nay
#   2. IAM Policy: dinh nghia quyen cua Lambda (DynamoDB, CloudWatch, S3, SES)
#   3. Attachment: gan policy vao role
#
# Kien thuc nen:
#   - IAM Role = "danh tinh" (identity) voi cac quyen cu the
#   - Trust Policy = "ai duoc phep dung role nay?" (o day la Lambda service)
#   - Permission Policy = "role nay duoc lam gi?" (o day la truy cap DynamoDB, ghi log)
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. IAM Role cho Lambda
# ------------------------------------------------------------------------------
# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role
#
# `assume_role_policy` (bat buoc): Trust policy - xac dinh service nao duoc assume role.
# Format: JSON policy document voi "Principal" la service ARN.
#
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
#
# Policy nay cap quyen:
#   - DynamoDB: doc/ghi/query/scan/update/delete items trong cac table Coffee*
#   - CloudWatch Logs: ghi logs de debug (bat buoc cho moi Lambda)
#   - S3: doc/ghi objects trong bucket chua anh san pham
#   - SES: gui email xac nhan don hang (su dung sau)
#
# Best Practice - Principle of Least Privilege:
# https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html#grant-least-privilege
# Chi cap dung quyen can thiet, khong dung wildcard (*) cho Resource khi co the.
# ------------------------------------------------------------------------------
resource "aws_iam_policy" "lambda_policy" {
  name        = var.policy_name
  description = "Permissions for Coffee Shop Lambda functions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # --- DynamoDB permissions ---
      # Cho phep Lambda doc/ghi du lieu trong cac DynamoDB tables
      # Resource dung pattern "Coffee*" de match tat ca tables cua project
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
# 3. Gan (attach) Policy vao Role
# ------------------------------------------------------------------------------
# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment
#
# Mot Role co the co nhieu Policies. O day ta attach:
#   - CoffeeLambdaPolicy (custom policy vua tao)
#
# Luu y: AWS cung co managed policies nhu AWSLambdaBasicExecutionRole
# nhung ta da dinh nghia CloudWatch Logs trong custom policy nen khong can.
# ------------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}
