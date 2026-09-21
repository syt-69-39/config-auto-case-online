# Apply 后输出本次执行结果，便于核验并作为执行记录。
# managed=false 表示指定资源已达目标态、本次为空操作（未做修正）。
output "result" {
  description = "本次执行结果：是否实际修正、目标标签 Key、以及修正后的实例摘要（空操作时为 null）。"
  value = {
    instance_id = var.instance_id
    ensured_key = var.tag_key
    managed     = length(local.manage) > 0
    instance = length(local.manage) > 0 ? {
      id      = volcenginecc_ecs_instance.target["target"].instance_id
      name    = volcenginecc_ecs_instance.target["target"].instance_name
      tags    = volcenginecc_ecs_instance.target["target"].tags
      zone_id = volcenginecc_ecs_instance.target["target"].zone_id
    } : null
  }
}
