terraform {
  backend "s3" {
    bucket         = ""
    key            = ""
    region         = ""

    use_lockfile = true

    # dynamodb_table = "terraform-up-and-running"
    # encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  required_version = ">= 1.2"
}