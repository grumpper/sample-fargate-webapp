
locals {
  name_prefix = join("-", [
    random_pet.random.id,
    data.aws_caller_identity.current.account_id,
    var.region,
    var.env
  ])
}