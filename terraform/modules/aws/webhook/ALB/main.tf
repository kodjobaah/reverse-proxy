resource "aws_security_group" "alb" {
  name        = "${var.project}-alb-${var.env}"
  description = "${var.project}-alb-${var.env}"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow world"
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow world"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Environment = var.env
    Group       = var.group
  }
}

## ALARM
#resource "aws_cloudwatch_metric_alarm" "alb_healthy_targets" {
#  alarm_name          = "${var.project}-healthy_targets-${var.env}"
#  comparison_operator = "LessThanThreshold"
#  evaluation_periods  = "1"
#  metric_name         = "HealthyHostCount"
#  namespace           = "AWS/ApplicationELB"
#  period              = "60"
#  statistic           = "Minimum"
#  threshold           = 1
#  alarm_description   = "Number of healthy nodes in Target Group"
#  alarm_actions       = [var.sns_topic]
#  treat_missing_data  = "breaching"
#  datapoints_to_alarm = 1
#
#  dimensions = {
#    TargetGroup  = aws_lb_target_group.lb_bg_target_group.arn_suffix
#    LoadBalancer = aws_lb.aws_bg_lb.arn_suffix
#  }
#}

resource "aws_lb" "alb" {
  name               = "${var.project}-alb-${var.env}"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnets_id
  load_balancer_type = "application"
  idle_timeout       = 60

  tags = {
    Name        = "${var.project}-${var.group}-alb-${var.env}"
    Environment = var.env
    Group       = var.group
  }
}

resource "aws_lb_target_group" "alb" {
  name                 = "${var.project}-target-group-${var.env}"
  port                 = 80
  protocol             = "HTTP"
  deregistration_delay = 60
  vpc_id               = var.vpc_id
  health_check {
    path                = "/"
    matcher             = "200-305"
    healthy_threshold   = 2
    interval            = 60
    unhealthy_threshold = 2
  }
  tags = {
    Environment = var.env
    Group       = var.group
  }
}

resource "aws_lb_listener" "lb_forward" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "redirect"
    target_group_arn = aws_lb_target_group.alb.arn
    redirect {
      status_code = "HTTP_301"
      host        = "${var.project}.afreixdev.com"
      path        = "/#{path}"
      port        = "443"
      protocol    = "HTTPS"
      query       = "#{query}"
    }
  }
}




#resource "aws_lb_target_group_attachment" "test" {
#  target_group_arn = aws_lb_target_group.test.arn
#  target_id        = aws_instance.test.id
#  port             = 80
#}




## FOR HTTPS

#resource "aws_lb_listener" "lb_redirect" {
#  load_balancer_arn = aws_lb.aws_bg_lb.arn
#  port              = "80"
#  protocol          = "HTTP"
#
#  default_action {
#    type = "redirect"
#
#    redirect {
#      port        = "443"
#      protocol    = "HTTPS"
#      status_code = "HTTP_301"
#    }
#  }
#}
#
#resource "aws_lb_listener" "lb_forwarding" {
#  load_balancer_arn = aws_lb.aws_bg_lb.arn
#  port              = "443"
#  protocol          = "HTTPS"
#  ssl_policy        = "ELBSecurityPolicy-2016-08"
#  certificate_arn   = var.ssl_certificate_arn
#
#  default_action {
#    type             = "forward"
#    target_group_arn = aws_lb_target_group.lb_bg_target_group.arn
#  }
#}

