variable "env" {
  type = string
}

variable "create_waf" {
  type    = bool
  default = true
}

variable "alb_arn" {
  type = string
}
