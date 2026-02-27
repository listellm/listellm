provider "aws" {
  region = "eu-west-2"

  default_tags {
    tags = {
      Project   = "listell"
      ManagedBy = "terraform"
    }
  }
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Project   = "listell"
      ManagedBy = "terraform"
    }
  }
}
