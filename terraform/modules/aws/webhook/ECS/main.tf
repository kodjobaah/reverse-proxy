#############
### ROLES ###
#############

data "aws_iam_policy_document" "s3_webhook_buckets" {
  statement {
    effect = "Allow"
    resources = [
      var.webhook_bucket.arn
    ]
    actions = ["s3:CreateBucket", "s3:ListBucket"]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }

  statement {
    effect = "Allow"
    resources = [
      "${var.webhook_bucket.arn}/*",
    ]
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:GetObject",
      "s3:DeleteObject"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameters",
      "secretsmanager:GetSecretValue"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "dynamodb:BatchGetItem",
      "dynamodb:GetItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:BatchWriteItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem"
    ]
    resources = ["arn:aws:dynamodb:eu-west-2:625194385885:table/WebhookProxy"]
  }
}
resource "aws_iam_role_policy" "s3_media_audit_buckets" {
  role   = aws_iam_role.ecs_task_execution_role.id
  policy = data.aws_iam_policy_document.s3_webhook_buckets.json
}

# ECS task execution role data
data "aws_iam_policy_document" "ecs_task_execution_role" {
  version = "2012-10-17"
  statement {
    sid     = ""
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# ECS task execution role
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.project}-${var.group}-${var.env}-EcsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_role.json
}

# ECS task execution role policy attachment
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "secret_manager_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

resource "aws_iam_role_policy_attachment" "amazon_ssm" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


################
### Security ###
################

resource "aws_security_group" "ecs_tasks" {
  name        = "${var.project}-${var.group}-ecs-tasks-webhook-security-group-${var.env}"
  description = "allow inbound access"
  vpc_id      = var.vpc_id.id

  ingress {
    protocol        = "tcp"
    from_port       = var.app_port
    to_port         = var.app_port
    security_groups = [aws_security_group.lb.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "lb" {
  name        = "${var.project}-${var.group}-load-balancer-security-group-${var.env}"
  description = "controls access to the ALB"
  vpc_id      = var.vpc_id.id

  ingress {
    protocol    = "tcp"
    from_port   = 3030
    to_port     = 3030
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

###################
### ECS Cluster ###
###################

resource "aws_ecs_cluster" "webhook" {
  name = "${var.project}-cluster-reverse-proxy"
}

locals {
  container_def = templatefile("${path.module}/templates/container_def_webhook.json.tpl", {
    app_webhook_image = var.ecr_webhook_url
    app_port          = var.app_port
    fargate_cpu       = var.fargate_cpu
    fargate_memory    = var.fargate_memory
    aws_region        = var.aws_region
    project           = var.project
    group             = var.group
    env               = var.env
    sm_arn            = var.secret_manager_arn
    env_variables     = var.env_variables
    dummy_arn         = var.dummy_arn
  })
}

resource "aws_ecs_task_definition" "webhook" {
  family                   = "${var.project}-${var.group}-${var.env}"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  container_definitions    = local.container_def
}

resource "aws_ecs_service" "main" {
  name                   = "${var.project}-${var.group}-service-${var.env}"
  cluster                = aws_ecs_cluster.webhook.id
  task_definition        = aws_ecs_task_definition.webhook.arn
  desired_count          = 1
  launch_type            = "FARGATE"
  enable_execute_command = true

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = var.subnets
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.id
    container_name   = "${var.project}-${var.env}-reverse-proxy"
    container_port   = var.app_port
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_execution_role,
  ]

}


#####################
### Load Balancer ###
#####################

resource "aws_alb" "main" {
  name            = "${var.project}-${var.group}-lb-${var.env}"
  subnets         = var.subnets
  security_groups = [aws_security_group.lb.id]
  idle_timeout    = 300
}

resource "aws_lb_target_group" "app" {
  name_prefix = "whook"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id.id
  target_type = "ip"
  slow_start  = 60

  stickiness {
    type = "lb_cookie"
  }

  health_check {
    healthy_threshold   = "10"
    interval            = "120"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "110"
    path                = "/status"
    unhealthy_threshold = "10"
  }
  lifecycle { create_before_destroy = true }
}

# Redirect all traffic from the ALB to the target group
resource "aws_alb_listener" "front_end" {
  load_balancer_arn = aws_alb.main.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.app.id
    type             = "redirect" ## forward / redirect
    redirect {
      status_code = "HTTP_301"
      host        = "#{host}"
      path        = "/#{path}"
      port        = "443"
      protocol    = "HTTPS"
      query       = "#{query}"
    }
  }
}

resource "aws_alb_listener" "front_end_ssl" {
  load_balancer_arn = aws_alb.main.id
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.webhook.arn
  default_action {
    target_group_arn = aws_lb_target_group.app.id
    type             = "forward"
  }
}

resource "aws_acm_certificate" "webhook" {
  domain_name       = "webhook.afriexdev.com"
  validation_method = "DNS"

  tags = {
    Environment = "${var.env}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "webhook" {
  for_each = {
    for dvo in aws_acm_certificate.webhook.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.route53_zone_api.zone_id
}

resource "aws_acm_certificate_validation" "webhook" {
  certificate_arn         = aws_acm_certificate.webhook.arn
  validation_record_fqdns = [for record in aws_route53_record.webhook : record.fqdn]
}
