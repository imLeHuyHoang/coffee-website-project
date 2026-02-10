variable "layer_name" {
  description = "Ten Lambda Layer"
  type        = string
  default     = "CoffeeNodeModules"
}

variable "layer_source_dir" {
  description = "Duong dan toi thu muc chua layer source (phai co nodejs/package.json + node_modules)"
  type        = string
}

variable "runtime" {
  description = "Node.js runtime version"
  type        = string
  default     = "nodejs20.x"
}
