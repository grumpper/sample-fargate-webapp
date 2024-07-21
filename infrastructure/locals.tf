locals {
  name_prefix = join("-", [
    var.region,
    var.env
  ])
}