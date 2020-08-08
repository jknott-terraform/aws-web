data "terraform_remote_state" "vpc"{
  backend = "s3"
  config = {
    region = var.region
    bucket = "engineering-remote-state-development"
    key = "vpc/terraform.tfstate"
  }
}


terraform {
  backend "s3" {
  bucket = "engineering-remote-state-development"
  key    = "web/terraform.tfstate"
  region = "us-east-1"
 }
}

