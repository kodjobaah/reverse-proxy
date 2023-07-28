provider "aws" {
  profile = "afriex"
  region  = "eu-west-2"
  version = "~> 4.0"
}

### Backend for S3 and DynamoDB ###
terraform {
  backend "s3" {
    bucket         = "afriex-terraform-webhook-codepipeline-state"
    key            = "terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "webhook-webhook-terraform-lock-codepipeline"
    profile        = "afriex"
    encrypt        = true
  }
}

###############################################################


# CodePipeline Service Role
#
# https://docs.aws.amazon.com/codepipeline/latest/userguide/how-to-custom-role.html

# https://www.terraform.io/docs/providers/aws/r/iam_role.html
resource "aws_iam_role" "webhook_code_pipeline_role" {
  name               = "codepipeline-webhook-role"
  assume_role_policy = data.aws_iam_policy_document.webhook_assume_role_policy.json
}

data "aws_iam_policy_document" "webhook_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

# https://www.terraform.io/docs/providers/aws/r/iam_policy.html
resource "aws_iam_policy" "webhook_code_pipeline_iam_policy" {
  name   = "codepipeline-webhook-policy"
  policy = data.aws_iam_policy_document.webhook_policy.json
}

data "aws_iam_policy_document" "webhook_policy" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObjectAcl",
      "s3:PutObject"
    ]

    resources = [
      "${aws_s3_bucket.artifact_bucket.arn}",
      "${aws_s3_bucket.artifact_bucket.arn}/*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "codestar-connections:UseConnection",
    ]

    resources = [
      var.codestar_connection_arn
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "iam:PassRole",
    ]

    resources = ["*"]
  }
}

# https://www.terraform.io/docs/providers/aws/r/iam_role_policy_attachment.html
resource "aws_iam_role_policy_attachment" "default" {
  role       = aws_iam_role.webhook_code_pipeline_role.name
  policy_arn = aws_iam_policy.webhook_code_pipeline_iam_policy.arn
}

resource "aws_s3_bucket" "artifact_bucket" {
  bucket = "afriex-codepipeline-webhook-artifact-bucket"
}

resource "aws_s3_bucket_acl" "artifact_bucket_acl" {
  bucket = aws_s3_bucket.artifact_bucket.id
  acl    = "private"
}

resource "aws_codepipeline" "static_web_pipeline" {
  name     = "webhook-pipeline"
  role_arn = aws_iam_role.webhook_code_pipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.artifact_bucket.id
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["SourceArtifact"]

      configuration = {
        ConnectionArn    = var.codestar_connection_arn
        FullRepositoryId = var.repository_ID
        BranchName       = var.repository_branch
      }
    }
  }

  stage {
    name = "Development"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["SourceArtifact"]
      output_artifacts = ["BuildArtifact"]
      version          = "1"

      configuration = {
        ProjectName = "webhook-proxy-dev"
      }
    }
  }

}
