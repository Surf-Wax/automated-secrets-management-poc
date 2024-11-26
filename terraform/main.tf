# Configure required providers for the infrastructure
terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure AWS Provider to use LocalStack (local AWS mock)
# LocalStack provides local AWS cloud stack for testing/development
provider "aws" {
  access_key = "test"  # Dummy credentials for LocalStack
  secret_key = "test"
  region     = "us-east-1"

  # Point AWS services to LocalStack endpoints instead of real AWS
  endpoints {
    iam = "http://127.0.0.1:4566"  # Identity and Access Management
    sts = "http://127.0.0.1:4566"  # Security Token Service
    ec2 = "http://127.0.0.1:4566"  # Elastic Compute Cloud
  }

  # Skip AWS-specific validations since we're using LocalStack
  skip_credentials_validation = true
  skip_metadata_api_check    = true
  skip_requesting_account_id = true
}

# Configure HashiCorp Vault provider
provider "vault" {
  address = "http://127.0.0.1:8200"  # Local Vault server address
  token   = "root"                    # Root token for development
}

# Create an IAM user whose credentials will be automatically rotated
resource "aws_iam_user" "app_user" {
  name = "application-service-user"
}

# Attach permissions policy to the application user
# This policy defines what AWS actions the user can perform
resource "aws_iam_user_policy" "app_user_permissions" {
  name = "application-permissions"
  user = aws_iam_user.app_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",  # Allow listing EC2 instances
          "ec2:DescribeImages",     # Allow listing AMIs
          "ec2:DescribeTags"        # Allow viewing EC2 tags
        ]
        Resource = "*"
      }
    ]
  })
}

# Create a special IAM user for Vault to manage credentials
# This user has permissions to create/delete access keys
resource "aws_iam_user" "vault_manager" {
  name = "vault-credentials-manager"
}

# Create initial access key for the Vault manager user
resource "aws_iam_access_key" "vault_manager_key" {
  user = aws_iam_user.vault_manager.name
}

# Define permissions for the Vault manager user
# These permissions allow Vault to rotate credentials for app_user
resource "aws_iam_user_policy" "vault_manager_permissions" {
  name = "vault-manager-permissions"
  user = aws_iam_user.vault_manager.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:CreateAccessKey",    # Allow creating new access keys
          "iam:DeleteAccessKey",    # Allow deleting old access keys
          "iam:ListAccessKeys"      # Allow listing existing access keys
        ]
        Resource = aws_iam_user.app_user.arn  # Only for app_user
      }
    ]
  })
}

# Configure Vault's AWS secrets engine
# This allows Vault to manage AWS credentials
resource "vault_aws_secret_backend" "aws" {
  path = "aws"  # Mount path in Vault
  
  # Credentials Vault uses to manage AWS resources
  access_key = aws_iam_access_key.vault_manager_key.id
  secret_key = aws_iam_access_key.vault_manager_key.secret

  # Point to LocalStack endpoints
  iam_endpoint = "http://localstack-main:4566"
  sts_endpoint = "http://localstack-main:4566"
  
  region = "us-east-1"
}

# Configure Vault's static role for credential rotation
# This defines which credentials to rotate and how often
resource "vault_aws_secret_backend_static_role" "app_credentials" {
  backend = vault_aws_secret_backend.aws.path
  name    = "app-credentials"
  
  username = aws_iam_user.app_user.name
  
  rotation_period = 61  # Rotate credentials every 61 seconds

  depends_on = [
    aws_iam_user_policy.app_user_permissions,
    aws_iam_user_policy.vault_manager_permissions
  ]
}

# Create a test EC2 instance in LocalStack
# This gives us something to query when testing credentials
resource "aws_instance" "test_instance" {
  ami           = "ami-test"  # Dummy AMI ID for LocalStack
  instance_type = "t2.micro"

  tags = {
    Name = "test-instance"
  }
}

# Create initial access key for the application user
resource "aws_iam_access_key" "app_user_key" {
  user = aws_iam_user.app_user.name
}

# Output initial credentials (for development/testing only)
output "initial_access_key" {
  value     = aws_iam_access_key.app_user_key.id
  sensitive = true
}

output "initial_secret_key" {
  value     = aws_iam_access_key.app_user_key.secret
  sensitive = true
}