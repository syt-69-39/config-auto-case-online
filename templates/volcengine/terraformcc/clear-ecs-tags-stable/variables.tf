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

# 这是一个已经存在的 ECS 实例。
# imports.tf 使用该变量将实例绑定到 volcenginecc_ecs_instance.target。
variable "instance_id" {
  description = "待清空标签的现有 ECS 实例 ID。"
  type        = string

  validation {
    condition     = startswith(var.instance_id, "i-")
    error_message = "instance_id 必须是以 i- 开头的 ECS 实例 ID。"
  }
}
