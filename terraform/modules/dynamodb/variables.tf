# ==============================================================================
# DynamoDB Module Variables
# ==============================================================================

variable "table_name_prefix" {
  description = "Prefix them vao truoc ten moi DynamoDB table (vd: 'Coffee' -> 'CoffeeProducts')"
  type        = string
  default     = "Coffee"
}

variable "tables" {
  description = <<-EOT
    Map cac DynamoDB tables can tao.
    Moi table gom:
      - name:       Ten table tren AWS
      - hash_key:   Partition key (bat buoc)
      - range_key:  Sort key (optional)
      - attributes: List cac key attributes { name, type }
                    Type: S = String, N = Number, B = Binary
      - global_secondary_indexes: List GSIs (optional)
  EOT

  type = map(object({
    name      = string
    hash_key  = string
    range_key = optional(string)
    attributes = list(object({
      name = string
      type = string # S = String, N = Number, B = Binary
    }))
    global_secondary_indexes = optional(list(object({
      name            = string
      hash_key        = string
      range_key       = optional(string)
      projection_type = optional(string, "ALL")
    })), [])
  }))

  # Default: 4 tables theo AWS_SETUP.md
  default = {
    products = {
      name     = "Products"
      hash_key = "productId"
      attributes = [
        { name = "productId", type = "S" }
      ]
    }

    orders = {
      name      = "Orders"
      hash_key  = "orderId"
      range_key = "createdAt"
      attributes = [
        { name = "orderId", type = "S" },
        { name = "createdAt", type = "N" },
        { name = "userId", type = "S" }
      ]
      global_secondary_indexes = [
        {
          name      = "userId-index"
          hash_key  = "userId"
          range_key = "createdAt"
        }
      ]
    }

    users = {
      name     = "Users"
      hash_key = "userId"
      attributes = [
        { name = "userId", type = "S" },
        { name = "email", type = "S" }
      ]
      global_secondary_indexes = [
        {
          name     = "email-index"
          hash_key = "email"
        }
      ]
    }

    reviews = {
      name      = "Reviews"
      hash_key  = "reviewId"
      range_key = "productId"
      attributes = [
        { name = "reviewId", type = "S" },
        { name = "productId", type = "S" }
      ]
      global_secondary_indexes = [
        {
          name     = "productId-index"
          hash_key = "productId"
        }
      ]
    }
  }
}

variable "billing_mode" {
  description = <<-EOT
    DynamoDB billing mode:
      PAY_PER_REQUEST = On-demand (tra theo so request, tot cho dev/unpredictable workload)
      PROVISIONED     = Dat truoc capacity (re hon cho stable workload)
    Doc: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.ReadWriteCapacityMode.html
  EOT
  type        = string
  default     = "PAY_PER_REQUEST"

  validation {
    condition     = contains(["PAY_PER_REQUEST", "PROVISIONED"], var.billing_mode)
    error_message = "Billing mode phai la PAY_PER_REQUEST hoac PROVISIONED."
  }
}

variable "enable_point_in_time_recovery" {
  description = "Bat Point-in-Time Recovery (khoi phuc data trong 35 ngay). Nen bat cho production."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags chung"
  type        = map(string)
  default     = {}
}
