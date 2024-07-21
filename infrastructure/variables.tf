variable "region" {
  type        = string
  description = "Which AWS region to deploy in?"
}

variable "env" {
  type    = string
  default = "Which environment this is deployed in?"
}

variable "image_tag" {
  type        = string
  description = "the container image tag used for deployment"
  default     = "latest"
}