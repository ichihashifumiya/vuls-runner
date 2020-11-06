provider "aws" {
  version = "2.70"

  profile = var.profile
  region  = var.region

  dynamic "assume_role" {
    for_each = [var.role_arn]

    content {
      role_arn = assume_role.value
    }
  }
}
