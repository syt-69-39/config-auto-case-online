# 第一步：只读查询现有 ECS 实例，回填 managed resource 的创建必填属性与现有标签。
# data 块不会修改实例，始终执行（用于判断指定资源当前是否已达目标态）。
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

  # 指定资源是否已含目标标签 Key（已达目标态）。
  has_target_key = contains([for t in local.existing_tags : t.key], var.tag_key)

  # 纳管开关：仅当「尚未达到目标态（缺目标标签）」时才 for_each 出一个元素并纳管+import。
  # 已达目标态时 manage 为空 → 不 import、无 resource 实例 → 本次执行 plan 为空、0 变更。
  # 这样在规则未锁资源范围、多个不合规资源各触发一次执行时，对指定资源只做「一次」真正修正，
  # 其余执行为瞬时空操作（幂等短路）。
  manage = local.has_target_key ? {} : { target = var.instance_id }

  # 最终标签集合 = 现有标签 ∪ {tag_key}，仅新增不删除其它标签。
  desired_tags = concat(local.existing_tags, [{ key = var.tag_key, value = var.tag_value }])
}

# 第二步：将既有实例 Import 到当前独立 State，并声明目标标签集合。
# for_each = local.manage：仅在需要修正时创建这个纳管实例；已达目标态则不创建（空操作）。
resource "volcenginecc_ecs_instance" "target" {
  for_each = local.manage

  image = {
    image_id = data.volcenginecc_ecs_instance.target.image.image_id
  }
  instance_name             = data.volcenginecc_ecs_instance.target.instance_name
  instance_type             = data.volcenginecc_ecs_instance.target.instance_type
  primary_network_interface = {}
  system_volume = {
    # 该字段在 schema 中有默认值；从现有实例回填，避免 Import 后发生替换。
    delete_with_instance = data.volcenginecc_ecs_instance.target.system_volume.delete_with_instance
  }
  zone_id = data.volcenginecc_ecs_instance.target.zone_id

  # 确保目标标签存在（现有标签 ∪ {tag_key}）。
  tags = toset(local.desired_tags)

  lifecycle {
    # 该实例在模板外创建；即使误执行 destroy，也绝不允许删除它。
    prevent_destroy = true

    # 只想 in-place 更新 tags；实例的结构/创建属性（含 ForceNew 项）一律以 State 中的
    # 真实值为准，忽略配置侧回填值的任何差异，避免 provider 把 plan 判成销毁重建(replace)
    # 从而触发 prevent_destroy 报错。
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
