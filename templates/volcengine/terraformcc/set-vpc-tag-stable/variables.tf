# 当前模板默认使用 BOE 地域，也允许执行环境覆盖。
variable "region" {
  description = "火山引擎地域。"
  type        = string
  default     = "cn-guilin-boe"
}

variable "cloud_control_endpoint" {
  description = "CloudControl API 接入地址。"
  type        = string
  default     = "cloudcontrol.cn-guilin-boe.volcengineapi-test.com"
}

# 这是一个已经存在的 VPC。
# imports.tf 使用该变量将 VPC 绑定到 volcenginecc_vpc_vpc.target。
variable "vpc_id" {
  description = "待打标签的现有 VPC ID。"
  type        = string

  validation {
    condition     = startswith(var.vpc_id, "vpc-")
    error_message = "vpc_id 必须是以 vpc- 开头的 VPC ID。"
  }
}

# 要确保存在于 VPC 上的标签 Key（幂等 add-or-keep）。
# Config Deploy 修正据此把资源从「缺该标签(不合规)」翻转为「含该标签(合规)」。
variable "tag_key" {
  description = "要在目标 VPC 上确保存在的标签 Key。"
  type        = string

  validation {
    condition     = length(var.tag_key) > 0
    error_message = "tag_key 不能为空。"
  }
}

# 该标签 Key 对应的 Value（默认空串，与控制台「仅 Key」标签一致）。
variable "tag_value" {
  description = "标签 Value，默认空串。"
  type        = string
  default     = ""
}
