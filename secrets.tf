# ── SSM Parameters ───────────────────────────────────────────────────────────────
resource "aws_ssm_parameter" "db_password" {
  name  = "/lab007/db_password"
  type  = "SecureString"
  value = var.db_password

  tags = { Name = "lab007-db-password" }
}

resource "aws_ssm_parameter" "app_env" {
  name  = "/lab007/app_env"
  type  = "String"
  value = var.app_env

  tags = { Name = "lab007-app-env" }
}

# ── IAM Role for EC2 → SSM access ────────────────────────────────────────────────
resource "aws_iam_role" "ec2_role" {
  name = "lab007-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = { Name = "lab007-ec2-ssm-role" }
}

resource "aws_iam_role_policy" "ssm_read" {
  name = "lab007-ssm-read"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ssm:GetParameter", "ssm:GetParameters", "ssm:GetParametersByPath"]
      Resource = "arn:aws:ssm:${var.region}:*:parameter/lab007/*"
    }]
  })
}

resource "aws_iam_instance_profile" "profile" {
  name = "lab007-ec2-profile"
  role = aws_iam_role.ec2_role.name
}
