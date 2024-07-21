# Create VPC for the Fargate and the ALB
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.9.0"

  name = "${local.name_prefix}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.region}a", "${var.region}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = false
}

# Create ALB to expose the Fargate service
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "9.9.0"

  name                       = "${local.name_prefix}-alb"
  load_balancer_type         = "application"
  vpc_id                     = module.vpc.vpc_id
  subnets                    = module.vpc.public_subnets
  enable_deletion_protection = false

  # Security Group
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
#     all_https = {
#       from_port   = 443
#       to_port     = 443
#       ip_protocol = "tcp"
#       description = "HTTPS web traffic"
#       cidr_ipv4   = "0.0.0.0/0"
#     }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "10.0.0.0/16"
    }
  }

  listeners = {
    #     http-https-redirect = {
    #       port     = 80
    #       protocol = "HTTP"
    #       redirect = {
    #         port        = "443"
    #         protocol    = "HTTPS"
    #         status_code = "HTTP_301"
    #       }
    #     }
    #     https = {
    #       port            = 443
    #       protocol        = "HTTPS"
    #       certificate_arn = "arn:aws:iam::123456789012:server-certificate/test_cert-123456789012"
    #
    #       forward = {
    #         target_group_key = "fargate"
    #       }
    #     }
    http = {
      port            = 80
      protocol        = "HTTP"

      forward = {
        target_group_key = "fargate"
      }
    }
  }

  target_groups = {
    fargate = {
      name_prefix = "h1"
      protocol    = "HTTP"
      port        = 80
      target_type = "ip"
    }
  }
}

# Create Fargate cluster, task definition and service
module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "5.11.3"

  cluster_name       = "${local.name_prefix}-cluster"
  capacity_providers = ["FARGATE"]
  default_capacity_provider_strategy = {
    capacity_provider = "FARGATE"
    weight            = 1
  }

  services = {
    flask-helloworld = {
      cpu    = 256
      memory = 512

      # Container definition(s)
      container_definitions = {

        flask-helloworld = {
          cpu       = 256
          memory    = 512
          essential = true
          image     = "${aws_ecr_repository.registry.repository_url}:latest"
          port_mappings = [
            {
              name          = "flask-helloworld"
              containerPort = 80
              protocol      = "tcp"
            }
          ]
          enable_cloudwatch_logging = false
        }
      }

      load_balancer = {
        service = {
          target_group_arn = module.alb.target_groups["fargate"].arn
          container_name   = "flask-helloworld"
          container_port   = 80
        }
      }

      subnet_ids = module.vpc.private_subnets
      security_group_rules = {
        alb_ingress_3000 = {
          type                     = "ingress"
          from_port                = 80
          to_port                  = 80
          protocol                 = "tcp"
          description              = "Service port"
          source_security_group_id = module.alb.security_group_id
        }
        egress_all = {
          type        = "egress"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
    }
  }
}

