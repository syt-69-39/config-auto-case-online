# 第一步：只读查询现有 ECS 实例，回填 managed resource 的创建必填属性。
# data 块不会修改实例。
data "volcenginecc_ecs_instance" "target" {
  id = var.instance_id
}

# 第二步：将既有实例 Import 到当前独立 State，并把标签清空为 []。
# 所有创建必填属性均取自刚读取的实例；不改动电源状态等其它配置。
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

  # 清空全部标签。
  tags = toset([])

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
