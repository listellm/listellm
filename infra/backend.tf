terraform {
  backend "s3" {
    bucket       = "listell-co-uk-terraform-state"
    key          = "holding-page/terraform.tfstate"
    region       = "eu-west-2"
    encrypt      = true
    use_lockfile = true
  }
}
