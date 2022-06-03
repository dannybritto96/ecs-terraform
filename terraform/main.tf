terraform {
  cloud {
    organization = "dannybritto96"

    workspaces {
      name = "ecs-dev"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_vpc" "vpc" {
  cidr_block           = var.VPC_CIDR
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.VPCName
    env  = var.env
  }
}

resource "aws_subnet" "privatesubnet1" {
  vpc_id               = aws_vpc.vpc.id
  cidr_block           = var.privateCIDR1
  availability_zone_id = var.AZId1

  tags = {
    Name = "${var.VPCName}-${var.env}-private-subnet-1"
    env  = var.env
  }
}

resource "aws_subnet" "privatesubnet2" {
  vpc_id               = aws_vpc.vpc.id
  cidr_block           = var.privateCIDR2
  availability_zone_id = var.AZId2

  tags = {
    Name = "${var.VPCName}-${var.env}-private-subnet-2"
    env  = var.env
  }
}

resource "aws_subnet" "publicsubnet1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.publicCIDR1
  map_public_ip_on_launch = true
  availability_zone_id    = var.AZId1

  tags = {
    Name = "${var.VPCName}-${var.env}-public-subnet-1"
    env  = var.env
  }
}

resource "aws_subnet" "publicsubnet2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.publicCIDR2
  map_public_ip_on_launch = true
  availability_zone_id    = var.AZId2

  tags = {
    Name = "${var.VPCName}-${var.env}-public-subnet-2"
    env  = var.env
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.VPCName}-${var.env}-igw"
    env  = var.env
  }
}

resource "aws_eip" "nat_ip" {
  vpc = true
}

resource "aws_nat_gateway" "nat" {
  subnet_id     = aws_subnet.publicsubnet1.id
  allocation_id = aws_eip.nat_ip.id
}

resource "aws_route" "private_route" {
  route_table_id         = aws_vpc.vpc.default_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "table_association1" {
  subnet_id      = aws_subnet.privatesubnet1.id
  route_table_id = aws_vpc.vpc.default_route_table_id
}

resource "aws_route_table_association" "table_association2" {
  subnet_id      = aws_subnet.privatesubnet2.id
  route_table_id = aws_vpc.vpc.default_route_table_id
}

resource "aws_route_table" "route_table1" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.VPCName}-${var.env}-rtb-1"
    env  = var.env
  }
}

resource "aws_route_table_association" "table_association3" {
  subnet_id      = aws_subnet.publicsubnet1.id
  route_table_id = aws_route_table.route_table1.id
}

resource "aws_route_table_association" "table_association4" {
  subnet_id      = aws_subnet.publicsubnet2.id
  route_table_id = aws_route_table.route_table1.id
}

data "aws_caller_identity" "current" {}


resource "aws_kms_key" "kms_key" {
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  is_enabled               = true
  enable_key_rotation      = true
  policy                   = <<EOT
{
  "Version": "2012-10-17",
  "Id": "Key Policy",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action": "kms:*",
      "Resource" : "*"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "${aws_iam_role.task_role.arn}"
        ]
      },
      "Action": [
        "kms:Create*",
        "kms:Describe*",
        "kms:Enable*",
        "kms:List*",
        "kms:Put*",
        "kms:Update*",
        "kms:Revoke*",
        "kms:Disable*",
        "kms:Get*",
        "kms:Delete*",
        "kms:Import*",
        "kms:RetireGrant"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Service" : [
          "logs.us-east-1.amazonaws.com",
          "ecs.amazonaws.com"
        ]
      },
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Describe*"
      ],
      "Resource": "*"
    }
  ]
}
EOT

  tags = {
    env = var.env
  }
}

resource "aws_kms_alias" "key_alias" {
  name          = "alias/app-dev-key"
  target_key_id = aws_kms_key.kms_key.key_id
}

resource "aws_ecr_repository" "service1" {
  name = "flask-service-1"
  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.kms_key.arn
  }

  tags = {
    "service" = "flask-service-1"
    "env"     = var.env
  }

}


resource "aws_iam_role" "task_role" {
  name = "TaskRole-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  inline_policy {
    name = "task-policy-${var.env}"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "kms:Encrypt",
            "kms:Decrypt"
          ]
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action = [
            "ecr:Get*",
            "ecr:List*",
            "ecr:BatchGetImage",
            "ecr:Describe*",
            "ecr:BatchCheckLayer*",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
          Effect   = "Allow"
          Resource = "*"
        }
      ]
    })
  }
}

resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name = "app-ecs-${var.env}-log-group"
}

resource "aws_security_group" "alb_sg" {
  name   = "alb-sg-${var.env}"
  vpc_id = aws_vpc.vpc.id

  ingress {
    description = "Allow 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }

  tags = {
    Name = "alb-sg-${var.env}"
    env  = var.env
  }
}


resource "aws_lb" "alb" {
  name               = "service-alb-${var.env}"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.privatesubnet1.id, aws_subnet.privatesubnet2.id]
  tags = {
    env = var.env
  }
}

resource "aws_lb_target_group" "tg1" {
  name        = "app-${var.env}-tg"
  port        = 5002
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.vpc.id

  health_check {
    enabled           = true
    healthy_threshold = 3
    interval          = 30
    path              = "/"
    port              = "traffic-port"
    protocol          = "HTTP"
    matcher           = "404"
  }
}

resource "aws_lb_listener" "listener1" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg1.arn
  }
}

resource "aws_security_group" "service_1_sg" {
  name   = "flask-service-1-sg-${var.env}"
  vpc_id = aws_vpc.vpc.id

  ingress {
    description     = "Allow 5002"
    from_port       = 5002
    to_port         = 5002
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "flask-service-1-sg-${var.env}"
    env  = var.env
  }
}

resource "aws_ecs_cluster" "cluster" {
  name = "app-ecs-${var.env}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  configuration {
    execute_command_configuration {
      kms_key_id = aws_kms_key.kms_key.arn
      logging    = "OVERRIDE"

      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.ecs_log_group.name
      }

    }
  }
}

resource "aws_ecs_task_definition" "service1" {
  family = "flask-service-1"
  cpu    = 256

  memory                   = 512
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
  execution_role_arn = aws_iam_role.task_role.arn

  depends_on = [
    aws_iam_role.task_role
  ]

  container_definitions = jsonencode([
    {
      name      = "flask-service-1"
      image     = "${aws_ecr_repository.service1.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 5002
          hostPort      = 5002
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "service_1" {
  name                              = "flask-service-1"
  cluster                           = aws_ecs_cluster.cluster.id
  task_definition                   = aws_ecs_task_definition.service1.arn
  health_check_grace_period_seconds = 30
  launch_type                       = "FARGATE"
  desired_count                     = 1

  load_balancer {
    target_group_arn = aws_lb_target_group.tg1.arn
    container_name   = "flask-service-1"
    container_port   = 5002
  }

  network_configuration {
    subnets          = [aws_subnet.privatesubnet1.id, aws_subnet.privatesubnet2.id]
    security_groups  = [aws_security_group.service_1_sg.id]
    assign_public_ip = false
  }
}

resource "aws_security_group" "gw_sg" {
  name   = "gw-sg-${var.env}"
  vpc_id = aws_vpc.vpc.id

  ingress {
    description = "Allow 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }

  tags = {
    Name = "gw-sg-${var.env}"
    env  = var.env
  }
}

resource "aws_apigatewayv2_vpc_link" "link" {
  name               = "${var.env}-vpc-lnk"
  security_group_ids = [aws_security_group.gw_sg.id]
  subnet_ids         = [aws_subnet.publicsubnet1.id, aws_subnet.publicsubnet2.id]
}

resource "aws_cloudwatch_log_group" "apigw_log_group" {
  name = "apigw-${var.env}-log-group"
}

resource "aws_apigatewayv2_api" "api_gw" {
  name                       = "ecs-dev"
  route_selection_expression = "$request.method $request.path"
  protocol_type              = "HTTP"
}

resource "aws_apigatewayv2_integration" "api_int" {
  api_id                 = aws_apigatewayv2_api.api_gw.id
  integration_type       = "HTTP_PROXY"
  integration_method     = "ANY"
  connection_type        = "VPC_LINK"
  integration_uri        = aws_lb_listener.listener1.arn
  payload_format_version = "1.0"
  connection_id          = aws_apigatewayv2_vpc_link.link.id
}

resource "aws_apigatewayv2_route" "api_route" {
  api_id    = aws_apigatewayv2_api.api_gw.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.api_int.id}"
}

resource "aws_apigatewayv2_stage" "example" {
  api_id      = aws_apigatewayv2_api.api_gw.id
  name        = "$default"
  auto_deploy = true
}