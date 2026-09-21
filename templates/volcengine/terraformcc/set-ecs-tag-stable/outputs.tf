# Apply 后输出目标实例摘要与最终标签，便于核验并作为执行记录。
output "target_ecs_instance" {
  description = "打标签操作后的目标 ECS 实例摘要。"
  value = {
    id           = volcenginecc_ecs_instance.target.instance_id
    name         = volcenginecc_ecs_instance.target.instance_name
    tags         = volcenginecc_ecs_instance.target.tags
    ensured_key  = var.tag_key
    zone_id      = volcenginecc_ecs_instance.target.zone_id
  }
}
