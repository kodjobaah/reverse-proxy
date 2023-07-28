data "aws_caller_identity" "current" {}

resource "aws_iam_role" "webhook" {
  name = "codebuild-${var.project}-service-role-${var.env}"
  path = "/service-role/"
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonECS_FullAccess",
    "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds",
    "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess",
    "arn:aws:iam::aws:policy/service-role/AWSAppSyncPushToCloudWatchLogs",
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
    "arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess"
  ]
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "codebuild" {
  statement {
    effect = "Allow"
    resources = [
      "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/weezy-marketplace-${var.env}",
      "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/weezy-marketplace-${var.env}:*",
    ]
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
  }

  statement {
    effect    = "Allow"
    resources = ["arn:aws:s3:::codepipeline-${var.region}-*"]
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation"
    ]
    resources = [
      aws_s3_bucket.build.arn,
      "${aws_s3_bucket.build.arn}/*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = ["*"]
  }
  statement {
    effect    = "Allow"
    resources = [aws_s3_bucket.build.arn, "${aws_s3_bucket.build.arn}/*"]
    actions = [
      "s3:PutObject",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation"
    ]
  }

  statement {
    effect    = "Allow"
    resources = [aws_codebuild_report_group.codebuild.arn]
    actions = [
      "codebuild:CreateReportGroup",
      "codebuild:CreateReport",
      "codebuild:UpdateReport",
      "codebuild:BatchPutTestCases",
      "codebuild:BatchPutCodeCoverages"
    ]
  }

  statement {
    effect    = "Allow"
    resources = [var.bastion-secretmanager_private_key_arn]
    actions = [
      "secretsmanager:GetSecretValue"
    ]
  }
}

resource "aws_iam_role_policy" "codebuild" {
  role   = aws_iam_role.webhook.id
  policy = data.aws_iam_policy_document.codebuild.json
}

resource "aws_s3_bucket" "build" {
  bucket = "afriex-${var.project}-${var.group}-build-webhook-${var.env}"
  tags = {
    Name        = "${var.project}-${var.group}-build-webhook-${var.env}"
    Environment = var.env
  }
}

resource "aws_s3_bucket_acl" "example" {
  bucket = aws_s3_bucket.build.id
  acl    = "private"
}

resource "aws_kms_key" "code-build" {
  description             = "code-build-webhook-bucket"
  deletion_window_in_days = 7

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "kms-tf-1",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "kms:*",
      "Resource": "*"
    }
  ]
}
POLICY
}


data "template_file" "buildspec" {
  template = file("../../modules/aws/webhook/CodeBuild/${var.env}/buildspec.yml")
  vars = {
    webhook_uri                           = var.webhook_uri,
    cluster_name                          = var.ecs_cluster_name,
    service_name                          = var.ecs_service_name,
    region                                = var.region
    acc_id                                = data.aws_caller_identity.current.account_id
    report_group_arn                      = aws_codebuild_report_group.codebuild.arn
    bastion_host_ip                       = var.bastion_host_ip
    bastion-secretmanager_private_key_arn = var.bastion-secretmanager_private_key_arn
    env                                   = var.env
    log_group                             = var.log_group
  }
}

resource "aws_codebuild_source_credential" "github_personal_access_token" {
  auth_type   = "PERSONAL_ACCESS_TOKEN"
  server_type = "GITHUB"
  token       = var.github_personal_access_token
}

resource "aws_codebuild_project" "backend" {
  name          = "${var.project}-${var.group}-${var.env}"
  description   = "${var.project}-${var.group}-${var.env}"
  build_timeout = "30"
  service_role  = aws_iam_role.webhook.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type = "NO_CACHE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_MEDIUM"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = "true"

    environment_variable {
      name  = "hub_username"
      value = "afriex"
    }

    environment_variable {
      name  = "hub_password"
      type  = "SECRETS_MANAGER"
      value = var.docker_hub_password.arn
    }

  }

  logs_config {
    s3_logs {
      status              = "ENABLED"
      location            = "${aws_s3_bucket.build.id}/codebuild_logs"
      encryption_disabled = "true"
    }

    cloudwatch_logs {
      group_name  = "/codebuild/webhook-proxy-${var.env}"
      stream_name = "webhook-proxy-${var.env}"
    }
  }

  source {
    type            = "GITHUB"
    git_clone_depth = 1
    location        = "https://github.com/kodjobaah/afriex-webhook-proxy.git"
    buildspec       = data.template_file.buildspec.rendered
    git_submodules_config {
      fetch_submodules = false
    }
  }


  tags = {
    Environment = var.env
  }
}

resource "aws_codebuild_report_group" "codebuild" {
  name = "${var.project}-${var.group}-${var.env}"
  type = "TEST"

  export_config {
    type = "S3"

    s3_destination {
      bucket              = aws_s3_bucket.build.id
      encryption_disabled = false
      packaging           = "NONE"
      path                = "/reports/${var.env}"
      encryption_key      = aws_kms_key.code-build.arn
    }
  }
}
