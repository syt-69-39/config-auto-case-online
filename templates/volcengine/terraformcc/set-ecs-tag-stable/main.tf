# 第一步：只读查询现有 ECS 实例，回填 managed resource 的创建必填属性与现有标签。
# data 块不会修改实例。
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

  # 已存在同名 Key 时不重复添加（幂等 add-or-keep）。
  has_target_key = contains([for t in local.existing_tags : t.key], var.tag_key)

  # 最终标签集合 = 现有标签 ∪ {tag_key}，仅新增不删除其它标签。
  desired_tags = local.has_target_key ? local.existing_tags : concat(
    local.existing_tags,
    [{ key = var.tag_key, value = var.tag_value }],
  )
}

# 第二步：将既有实例 Import 到当前独立 State，并声明目标标签集合。
# 所有创建必填属性均取自刚读取的实例；不改动电源状态等其它配置。
resource "volcenginecc_ecs_instance" "target" {
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
    # 该实例在模板外创建；即使误执行 tofu destroy，也绝不允许删除它。
    prevent_destroy = true
  }
}
