output "waf_arn" {
  value = var.create_waf ? aws_wafv2_web_acl.main[0].arn : null
}
