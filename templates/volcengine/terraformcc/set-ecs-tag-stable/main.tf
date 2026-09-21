# 只读查询现有 ECS 实例，回填 managed resource 的创建必填属性与现有标签。data 块不改实例。
data "volcenginecc_ecs_instance" "target" {
  id = var.instance_id
}

locals {
  # 现有标签集合（key/value 对）。
  existing_tags = [
    for t in coalesce(data.volcenginecc_ecs_instance.target.tags, toset([])) : {
      key   = t.key
      value = t.value
    }
  ]

  # 已含目标标签则保持现状（幂等），否则并入目标标签。仅新增不删除其它标签。
  has_target_key = contains([for t in local.existing_tags : t.key], var.tag_key)
  desired_tags = local.has_target_key ? local.existing_tags : concat(
    local.existing_tags,
    [{ key = var.tag_key, value = var.tag_value }],
  )
}

# 始终纳管指定实例并 import；靠「幂等 tags + ignore_changes」保证已达目标态时 plan 为空、0 变更。
# 规则未锁资源范围时，Config 为每个不合规资源各触发一次执行，但每次都操作写死的 instance_id：
# 第一次真正加标签，其余执行因指定资源已含标签而 plan 为空——即对指定资源只做「一次」真正修正，
# 多余执行为 0 变更空 apply（不 destroy、不 replace，避免 prevent_destroy 报错）。
resource "volcenginecc_ecs_instance" "target" {
  image = {
    image_id = data.volcenginecc_ecs_instance.target.image.image_id
  }
  instance_name             = data.volcenginecc_ecs_instance.target.instance_name
  instance_type             = data.volcenginecc_ecs_instance.target.instance_type
  primary_network_interface = {}
  system_volume = {
    delete_with_instance = data.volcenginecc_ecs_instance.target.system_volume.delete_with_instance
  }
  zone_id = data.volcenginecc_ecs_instance.target.zone_id

  # 确保目标标签存在（现有标签 ∪ {tag_key}）。已含则等于现状，无 diff。
  tags = toset(local.desired_tags)

  lifecycle {
    # 该实例在模板外创建；即使误执行 destroy，也绝不允许删除它。
    prevent_destroy = true

    # 只想 in-place 更新 tags；实例结构/创建属性（含 ForceNew 项）一律以 State 真实值为准，
    # 避免 provider 把 plan 判成销毁重建(replace) 从而触发 prevent_destroy。
    ignore_changes = [
      image,
      instance_name,
      instance_type,
      primary_network_interface,
      system_volume,
      zone_id,
      status,
      stopped_mode,
    ]
  }
}
