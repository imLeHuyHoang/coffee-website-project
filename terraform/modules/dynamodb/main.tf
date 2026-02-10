# ==============================================================================
# DynamoDB Module - Coffee Shop Tables
# ==============================================================================
# Doc goc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table
#
# Module nay tao 4 DynamoDB tables:
#   1. CoffeeProducts  (productId PK)
#   2. CoffeeOrders    (orderId PK, createdAt SK, GSI: userId-index)
#   3. CoffeeUsers     (userId PK, GSI: email-index)
#   4. CoffeeReviews   (reviewId PK, productId SK, GSI: productId-index)
#
# Kien thuc nen:
#   DynamoDB la NoSQL database cua AWS - serverless, tu dong scale.
#   Khong can tao server, khong can quan ly storage, chi tra tien theo request.
#
#   Cac khai niem quan trong:
#   - Partition Key (PK): Khoa chinh, dung de phan phoi data across partitions
#   - Sort Key (SK): Khoa phu, ket hop voi PK tao nen composite primary key
#   - GSI (Global Secondary Index): "Bang phu" cho phep query theo attribute khac PK
#     Vi du: CoffeeUsers co PK = userId, nhung ta can tim user theo email
#     -> Tao GSI voi email la partition key
#   - Billing Mode:
#     PAY_PER_REQUEST (On-demand) = tra theo so request, tot cho workload khong doan truoc
#     PROVISIONED = dat truoc capacity, re hon neu workload on dinh
#
# TERRAFORM CONCEPTS MOI (Part 2):
#   - for_each:  Tao NHIEU resources tu 1 block (thay vi copy-paste)
#   - dynamic:   Tao NHIEU nested blocks ben trong 1 resource
#   - try():     Truy cap attribute AN TOAN (khong loi neu null)
#   - lookup():  Tim gia tri trong map voi fallback
#
# Doc for_each: https://developer.hashicorp.com/terraform/language/meta-arguments/for_each
# Doc dynamic:  https://developer.hashicorp.com/terraform/language/expressions/dynamic-blocks
# ==============================================================================

# ==============================================================================
# 1. DynamoDB Tables - Su dung for_each
# ==============================================================================
# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table
#
# THAY VI viet 4 resource blocks giong nhau (copy-paste):
#   resource "aws_dynamodb_table" "products" { ... }
#   resource "aws_dynamodb_table" "orders"   { ... }
#   resource "aws_dynamodb_table" "users"    { ... }
#   resource "aws_dynamodb_table" "reviews"  { ... }
#
# TA DUNG `for_each` de tao 4 tables tu 1 block duy nhat!
#
# `for_each` nhan 1 map hoac set -> tao 1 resource cho MOI phan tu.
# Trong resource, dung `each.key` va `each.value` de truy cap phan tu hien tai.
#
# Vi du: for_each = var.tables
#   each.key   = "products" (ten logic)
#   each.value = { name = "CoffeeProducts", hash_key = "productId", ... }
# ==============================================================================
resource "aws_dynamodb_table" "tables" {
  for_each = var.tables

  name         = "${var.table_name_prefix}${each.value.name}"
  billing_mode = var.billing_mode
  hash_key     = each.value.hash_key

  # Sort key la OPTIONAL - chi co neu table can composite primary key
  # `try()` function: thu truy cap attribute, neu khong co -> tra ve null
  # Doc: https://developer.hashicorp.com/terraform/language/functions/try
  range_key = try(each.value.range_key, null)

  # --------------------------------------------------------------------------
  # Attribute Definitions
  # --------------------------------------------------------------------------
  # Doc: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.NamingRulesDataTypes.html
  #
  # CHI KHAI BAO cac attributes dung lam KEY (PK, SK, GSI key).
  # DynamoDB la schemaless - cac attributes khac KHONG can khai bao truoc.
  # Chung duoc tao tu dong khi ban PutItem.
  #
  # `dynamic` block: Tao NHIEU nested blocks tu 1 list/map
  # Doc: https://developer.hashicorp.com/terraform/language/expressions/dynamic-blocks
  #
  # Tai sao dung dynamic thay vi viet tay?
  # - Moi table co SO LUONG ATTRIBUTES KHAC NHAU (1, 2, 3 hoac 4)
  # - Viet tay -> phai tao 4 resource blocks rieng biet
  # - dynamic -> 1 block, loop qua danh sach attributes
  #
  # Cau truc:
  #   dynamic "attribute" {          # Ten cua nested block can lap lai
  #     for_each = [...]             # List de loop qua
  #     content {                    # Noi dung cua moi block
  #       name = attribute.value.name
  #       type = attribute.value.type
  #     }
  #   }
  # --------------------------------------------------------------------------
  dynamic "attribute" {
    for_each = each.value.attributes
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  # --------------------------------------------------------------------------
  # Global Secondary Indexes (GSIs)
  # --------------------------------------------------------------------------
  # Doc: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/GSI.html
  # Doc Terraform: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table#global_secondary_index
  #
  # GSI cho phep query data theo attribute KHAC partition key.
  # Vi du: Table CoffeeUsers co PK = userId
  #   Nhung khi login, ta co EMAIL, khong co userId
  #   -> Tao GSI voi partition key = email -> query theo email
  #
  # Moi GSI nhu mot "table clone" voi key schema rieng.
  # DynamoDB tu dong dong bo data giua table chinh va GSI.
  #
  # `lookup()`: Tim gia tri trong map, neu khong co -> tra ve default
  # Doc: https://developer.hashicorp.com/terraform/language/functions/lookup
  #
  # `try(..., [])`: Neu each.value.global_secondary_indexes khong ton tai
  # -> tra ve list rong [] -> dynamic block khong tao block nao
  # --------------------------------------------------------------------------
  dynamic "global_secondary_index" {
    for_each = try(each.value.global_secondary_indexes, [])
    content {
      name            = global_secondary_index.value.name
      hash_key        = global_secondary_index.value.hash_key
      range_key       = lookup(global_secondary_index.value, "range_key", null)
      projection_type = lookup(global_secondary_index.value, "projection_type", "ALL")
    }
  }

  # --------------------------------------------------------------------------
  # Point-in-time Recovery (PITR)
  # --------------------------------------------------------------------------
  # Doc: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/PointInTimeRecovery.html
  #
  # PITR cho phep khoi phuc table ve bat ky thoi diem nao trong 35 ngay.
  # Giong nhu "undo" cho database.
  # Nen BAT cho production. Trong dev co the tat de tiet kiem chi phi.
  # --------------------------------------------------------------------------
  point_in_time_recovery {
    enabled = var.enable_point_in_time_recovery
  }

  # --------------------------------------------------------------------------
  # Tags
  # --------------------------------------------------------------------------
  tags = merge(var.tags, {
    TableName = each.value.name
  })
}
