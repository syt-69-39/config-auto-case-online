# set-vpc-tag-stable

为一个已存在的 VPC 幂等补齐指定标签。

该模板模仿 `set-ecs-tag-stable` 的修正方式：

- 使用 `data.volcenginecc_vpc_vpc` 只读目标 VPC 当前属性与标签。
- 使用 OpenTofu 配置式 `import` 将目标 VPC 纳管到 `volcenginecc_vpc_vpc.target`。
- 将现有标签与目标标签做并集，只新增缺失的目标标签，不删除其它标签。
- 使用 `prevent_destroy = true` 避免误删已有 VPC。
- 使用 `ignore_changes` 忽略非标签属性，避免现有 VPC 被重建。

## 变量

| 变量 | 说明 | 默认值 |
| --- | --- | --- |
| `region` | 火山引擎地域 | `cn-guilin-boe` |
| `cloud_control_endpoint` | CloudControl API 接入地址 | `cloudcontrol.cn-guilin-boe.volcengineapi-test.com` |
| `vpc_id` | 待修正的现有 VPC ID | 无，必填 |
| `tag_key` | 需要确保存在的标签 Key | 无，必填 |
| `tag_value` | 标签 Value | `""` |

## 示例

```hcl
vpc_id    = "vpc-xxxxxxxx"
tag_key   = "config-remediation"
tag_value = "true"
```
