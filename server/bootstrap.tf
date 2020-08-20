provider "aws" {
  version = "~> 2.0"
  region  = "us-east-2"
  profile = "default"
}

terraform {
  backend "s3" {
    bucket = "spotifyaml"
    key    = "server.tfstate"
    region = "us-east-2"
  }
}
