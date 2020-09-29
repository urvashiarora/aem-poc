provider "aws" {
  version             = "~> 1.9"
  region              = "eu-west-1"
  allowed_account_ids = ["${var.account_id}"]

  assume_role {
    role_arn = "arn:aws:iam::${var.account_id}:role/terraform"
  }
}
