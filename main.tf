terraform {
  required_version = "~> 1.1.2"

  required_providers {
    aws = {
      version = "~> 4.9.0"
      source  = "hashicorp/aws"
    }
  }
}

# Download AWS provider
provider "aws" {
  region = "us-east-2"
  default_tags {
    tags = {
      Owner = "Playground Scenario 2"
      Admin = "Kyler"
    }
  }
}

# Grab current AWS info and region
data "aws_caller_identity" "current" {}

# These users are support team members
resource "aws_iam_user" "support_iam_users" {
  for_each = toset(
    [
      "Olivia.Alexander",
      "Liam.Mia",
      "Benjamin.Amelia",
    ]
  )
  name = each.key
}

resource "aws_iam_group" "SupportStaff" {
  name = "SupportStaff"
}

resource "aws_iam_group_membership" "SupportGroupMembership" {
  name = "Support-Group-Membership"
  users = [
    for v in aws_iam_user.support_iam_users : v.name
  ]
  group = aws_iam_group.SupportStaff.name
}

resource "aws_iam_group_policy_attachment" "SupportPermitAll" {
  group      = aws_iam_group.SupportStaff.name
  policy_arn = aws_iam_policy.PermitAllPolicy.arn
}

# Create policy for users to permit all
resource "aws_iam_policy" "PermitAllPolicy" {
  name        = "PermitAllPolicy"
  description = "Permit all actions"
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "GlobalAdmins",
          "Effect" : "Allow",
          "Action" : "*",
          "Resource" : "*",
        }
      ]
    }
  )
}

# These users are admin team members
resource "aws_iam_user" "admin_iam_users" {
  for_each = toset(
    [
      "William.Collins",
      "Henry.Mason",
      "Evelyn.Jason",
    ]
  )
  name = each.key
}

resource "aws_iam_group" "AdminStaff" {
  name = "AdminStaff"
}

resource "aws_iam_group_membership" "AdminGroupMembership" {
  name = "Admin-Group-Membership"
  users = [
    for v in aws_iam_user.admin_iam_users : v.name
  ]
  group = aws_iam_group.AdminStaff.name
}

resource "aws_iam_group_policy_attachment" "AdminPermitAll" {
  group      = aws_iam_group.AdminStaff.name
  policy_arn = aws_iam_policy.PermitAllPolicy.arn
}

resource "aws_kms_key" "ecr_cmk" {
  description = "KMS Key for ECR for Scenario 2"
}

# Create alias for easy KMS key finding
resource "aws_kms_alias" "ecr_key_alias" {
  name          = "alias/kms-key-for-ecr-scenario2"
  target_key_id = aws_kms_key.ecr_cmk.key_id
}

# Create ECR with custom KMS key
resource "aws_ecr_repository" "ecr-for-scenario2" {
  name                 = "ecr-for-scenario2"
  image_tag_mutability = "MUTABLE"

  # Encrypt our ECR with custom KMS key, CMK we created above
  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.ecr_cmk.arn
  }

  image_scanning_configuration {
    scan_on_push = true
  }
}
