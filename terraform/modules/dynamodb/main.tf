resource "aws_dynamodb_table" "tables" {
  for_each = var.tables

  name         = "${var.table_name_prefix}${each.value.name}"
  billing_mode = var.billing_mode
  hash_key     = each.value.hash_key


  range_key = try(each.value.range_key, null)

  # --------------------------------------------------------------------------
  # Attribute Definitions
  # --------------------------------------------------------------------------
  # Doc: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.NamingRulesDataTypes.html
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
  dynamic "global_secondary_index" {
    for_each = try(each.value.global_secondary_indexes, [])
    content {
      name            = global_secondary_index.value.name
      hash_key        = global_secondary_index.value.hash_key
      range_key       = lookup(global_secondary_index.value, "range_key", null)
      projection_type = lookup(global_secondary_index.value, "projection_type", "ALL")
    }
  }

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
