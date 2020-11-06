variable region {
  type    = string
  default = "ap-northeast-1"
}

variable profile {
  type = string
}

variable role_arn {
  type    = string
  default = null
}

variable vpc_id {
  type = string
}

variable subnet_id {
  type = string
}

variable ssh_accepted_cidrs {
  type    = list(string)
  default = []
}

variable ssh_accepted_security_groups {
  type    = list(string)
  default = []
}

variable http_accepted_cidrs {
  type    = list(string)
  default = []
}

variable http_accepted_security_groups {
  type    = list(string)
  default = []
}

variable instance_security_group_ids {
  type    = list(string)
  default = []
}

variable ami_id {
  type    = string
  default = null
}

variable instance_type {
  type    = string
  default = "t2.small"
}

variable ec2_user_keyname {
  type = string
}

variable volume_size {
  type    = number
  default = 20
}

variable instance_name {
  type    = string
  default = "vuls-runner"
}

variable associate_public_ip_address {
  type    = bool
  default = false
}

# ここで指定するタグは、作成されるあらゆるリソースに適用される。
# EC2 インスタンスの名前を変更したい場合は、 instance_name を指定すること
variable tags {
  type = map(string)
  default = {
    Project = "vuls-runner"
  }
}
