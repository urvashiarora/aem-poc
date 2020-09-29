data "terraform_remote_state" "dns" {
  backend = "s3"

  config {
    region   = "eu-west-1"
    bucket   = "ctm-terraform-state"
    key      = "domains.default.tfstate"
    role_arn = "arn:aws:iam::482506117024:role/terraform"
  }
}
