variable aws_profile {
  type = string
}

variable region {
  type = string
  default = "ap-northeast-1"
}

variable vpc_id {
  type = string
}

variable subnet_id {
  type = string
}

variable spot_instance_types {
  type = list(string)
  default = ["t2.small"]
}

variable spot_price {
  type = string
  default = "0.0091"
}

variable ami_name {
  type = string
  default = "vuls-runner-ami-{{ timestamp }}"
}

variable ssh_ip {
  type = string
  default = ""
}

source amazon-ebs vuls_runner {
  profile = var.aws_profile
  region = var.region
  vpc_id = var.vpc_id
  subnet_id = var.subnet_id
  spot_instance_types = var.spot_instance_types
  spot_price = var.spot_price
  ssh_username = "ec2-user"
  ami_name = var.ami_name
  associate_public_ip_address = true
  ssh_interface = "public_ip"

  launch_block_device_mappings {
    device_name = "/dev/xvda"
    volume_size = 20
    volume_type = "gp2"
    delete_on_termination = true
  }

  source_ami_filter {
    filters = {
      virtualization-type = "hvm"
      name = "amzn2-ami-hvm-2.0.*-x86_64-gp2"
      root-device-type = "ebs"
    }
    owners = ["amazon"]
    most_recent = true
  }

  temporary_iam_instance_profile_policy_document {
    Version = "2012-10-17"
    Statement {
      Action = [
        "logs:CreateLogStream",
        "logs:CreateLogGroup",
        "logs:PutLogEvents"
      ]
      Resource = ["*"]
      Effect = "Allow"
    }
  }

  temporary_security_group_source_cidrs = [
    var.ssh_ip
  ]
}

build {
  sources = [
    "source.amazon-ebs.vuls_runner"
  ]

  provisioner shell {
    environment_vars = [
      "PACKER_AMI_NAME=${var.ami_name}",
      "AWS_REGION=${var.region}"
    ]
    scripts = ["./provisioner.sh"]
  }

  provisioner shell {
    environment_vars = [
      "PACKER_AMI_NAME=${var.ami_name}",
      "AWS_REGION=${var.region}"
    ]
    scripts = ["./install-vulnerability-dic.sh"]
  }
}
