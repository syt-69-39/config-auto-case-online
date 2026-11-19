# 只读查询现有 VPC，回填 managed resource 的创建必填属性与现有标签。data 块不改 VPC。
data "volcenginecc_vpc_vpc" "target" {
  id = var.vpc_id
}

locals {
  # 现有标签集合（key/value 对）。
  existing_tags = [
    for t in coalesce(data.volcenginecc_vpc_vpc.target.tags, toset([])) : {
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

# 始终纳管指定 VPC 并 import；靠「幂等 tags + ignore_changes」保证已达目标态时 plan 为空、0 变更。
# 规则未锁资源范围时，Config 为每个不合规资源各触发一次执行，但每次都操作写死的 vpc_id：
# 第一次真正加标签，其余执行因指定资源已含标签而 plan 为空。
resource "volcenginecc_vpc_vpc" "target" {
  vpc_name              = data.volcenginecc_vpc_vpc.target.vpc_name
  cidr_block            = data.volcenginecc_vpc_vpc.target.cidr_block
  description           = data.volcenginecc_vpc_vpc.target.description
  project_name          = data.volcenginecc_vpc_vpc.target.project_name
  support_ipv_4_gateway = data.volcenginecc_vpc_vpc.target.support_ipv_4_gateway

  # 确保目标标签存在（现有标签 ∪ {tag_key}）。已含则等于现状，无 diff。
  tags = toset(local.desired_tags)

  lifecycle {
    # 该 VPC 在模板外创建；即使误执行 destroy，也绝不允许删除它。
    prevent_destroy = true

    # 只想 in-place 更新 tags；VPC 创建属性一律以 State 真实值为准，
    # 避免 provider 把 plan 判成销毁重建(replace) 从而触发 prevent_destroy。
    ignore_changes = [
      vpc_name,
      cidr_block,
      description,
      project_name,
      support_ipv_4_gateway,
      status,
    ]
  }
}
