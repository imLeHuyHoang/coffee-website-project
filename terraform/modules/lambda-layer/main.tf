
data "archive_file" "layer" {
  type        = "zip"
  source_dir  = var.layer_source_dir
  output_path = "${path.module}/builds/layer.zip"
}

resource "aws_lambda_layer_version" "dependencies" {
  layer_name          = var.layer_name
  filename            = data.archive_file.layer.output_path
  source_code_hash    = data.archive_file.layer.output_base64sha256
  compatible_runtimes = [var.runtime]

  description = "Shared npm packages: bcryptjs, jsonwebtoken"
}
