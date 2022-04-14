provider "aws" {
  region                   = "us-east-1"
  profile                  = "default"
  shared_credentials_files = ["~/.aws/credentials"]
}