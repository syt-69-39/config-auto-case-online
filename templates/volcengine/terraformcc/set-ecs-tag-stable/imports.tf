# OpenTofu 1.11.8 的 import.id 不能直接引用输入变量，用 for_each 后可通过 each.value 使用同一 ID。
# 关键：for_each 复用 local.manage —— 仅当指定资源「尚未达到目标态（缺目标标签）」时才纳管并 import；
# 若目标标签已存在（前一次执行已修正），local.manage 为空 → 本次执行不 import、不产生任何变更，
# 从而在「规则未锁资源范围、多个不合规资源各触发一次执行」时，对指定资源只做一次真正修正，
# 其余执行为瞬时空操作。
import {
  for_each = local.manage

  to = volcenginecc_ecs_instance.target[each.key]
  id = each.value
}
