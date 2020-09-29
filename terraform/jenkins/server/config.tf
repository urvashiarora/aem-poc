terraform {
    required_version = "~> 0.11.8"
    required_providers {
        aws = {
            source = "hashicorp/aws"
        }        
    }

    backend "s3" {
    region               = "eu-west-1"
    bucket               = "ctm-terraform"
    role_arn             = "arn:aws:iam::482506117024:role/terraform"
    workspace_key_prefix = "state/mit"
    key                  = "ci-jk-server.tfstate"
    encrypt              = "true"
    kms_key_id           = "arn:aws:kms:eu-west-1:482506117024:alias/terraform"
    acl                  = "bucket-owner-full-control"
  }
}
