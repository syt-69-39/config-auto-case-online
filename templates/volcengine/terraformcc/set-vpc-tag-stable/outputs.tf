# Apply 后输出目标 VPC 摘要与最终标签，便于核验并作为执行记录。
output "target_vpc" {
  description = "打标签操作后的目标 VPC 摘要。"
  value = {
    id          = volcenginecc_vpc_vpc.target.id
    name        = volcenginecc_vpc_vpc.target.vpc_name
    cidr_block  = volcenginecc_vpc_vpc.target.cidr_block
    tags        = volcenginecc_vpc_vpc.target.tags
    ensured_key = var.tag_key
    project     = volcenginecc_vpc_vpc.target.project_name
  }
}
