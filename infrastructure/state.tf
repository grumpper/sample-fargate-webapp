terraform {
  backend "s3" {
    key = "sample-fargate-webapp.tfstate"
  }
}
