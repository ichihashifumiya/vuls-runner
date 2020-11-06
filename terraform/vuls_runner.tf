data aws_caller_identity current {}

data aws_region current {}

data aws_vpc vuls_runner {
  id = var.vpc_id
}

data aws_subnet vuls_runner {
  id = var.subnet_id
}

data aws_iam_policy_document ec2_service_role {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data aws_iam_policy_document vuls_runner_instance_profile {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:PutLogEvents"
    ]

    resources = ["*"]
  }
}

resource aws_iam_role vuls_runner_instance_profile {
  name = "vuls-runner-ec2-role"

  assume_role_policy = data.aws_iam_policy_document.ec2_service_role.json

  tags = var.tags
}

resource aws_iam_role_policy vuls_runner_instance_profile {
  name = "vuls-runner-ec2-policy"
  role = aws_iam_role.vuls_runner_instance_profile.id

  policy = data.aws_iam_policy_document.vuls_runner_instance_profile.json
}

resource aws_iam_instance_profile vuls_runner {
  name = "vuls-runner-instance-profile"
  role = aws_iam_role.vuls_runner_instance_profile.name
}

resource aws_security_group vuls_runner {
  name   = "vuls-runner-security-group"
  vpc_id = data.aws_vpc.vuls_runner.id

  ingress {
    from_port       = 5111
    to_port         = 5111
    protocol        = "tcp"
    cidr_blocks     = var.http_accepted_cidrs
    security_groups = var.http_accepted_security_groups
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = var.ssh_accepted_cidrs
    security_groups = var.ssh_accepted_security_groups
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

data aws_ami vuls_runner_ami {
  most_recent = true
  name_regex  = "vuls-runner-ami-\\d+"
  owners      = ["self"]

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource aws_instance vuls_runner {
  ami                         = var.ami_id == null ? data.aws_ami.vuls_runner_ami.id : var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnet.vuls_runner.id
  vpc_security_group_ids      = concat([aws_security_group.vuls_runner.id], var.instance_security_group_ids)
  key_name                    = var.ec2_user_keyname
  iam_instance_profile        = aws_iam_instance_profile.vuls_runner.name
  associate_public_ip_address = var.associate_public_ip_address

  user_data_base64 = base64encode(
    templatefile("user_data.sh", {
      region        = data.aws_region.current.name,
      instance_name = var.instance_name
    })
  )

  root_block_device {
    volume_type = "gp2"
    volume_size = var.volume_size
  }

  tags = merge(var.tags, {
    Name   = var.instance_name
    ami_id = var.ami_id == null ? data.aws_ami.vuls_runner_ami.id : var.ami_id
  })
}

output vuls_runner_security_group_id {
  value = aws_security_group.vuls_runner.id
}

output vuls_runner_instance_id {
  value = aws_instance.vuls_runner.id
}

output vuls_runner_instance_public_ip {
  value = aws_instance.vuls_runner.public_ip
}

output vuls_runner_instance_private_ip {
  value = aws_instance.vuls_runner.private_ip
}
