# ── AMI: Latest Amazon Linux 2023 ────────────────────────────────────────────────
data "aws_ami" "amazon" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# ── Bastion Host ─────────────────────────────────────────────────────────────────
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  tags = { Name = "lab007-bastion" }
}

# ── Web Tier Launch Template ──────────────────────────────────────────────────────
# Injects backend_url (internal ALB DNS) and full_name into web.sh at deploy time
resource "aws_launch_template" "web" {
  name_prefix   = "lab007-web-"
  image_id      = data.aws_ami.amazon.id
  instance_type = var.instance_type
  key_name      = var.key_name

  iam_instance_profile {
    name = aws_iam_instance_profile.profile.name
  }

  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = base64encode(templatefile("userdata/web.sh", {
    backend_url = aws_lb.internal.dns_name
    full_name   = var.full_name
  }))

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "lab007-web" }
  }
}

# ── Web Tier Auto Scaling Group ───────────────────────────────────────────────────
resource "aws_autoscaling_group" "web" {
  name                = "lab007-web-asg"
  min_size            = 1
  max_size            = 4
  desired_capacity    = 2
  vpc_zone_identifier = aws_subnet.public[*].id

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "lab007-web"
    propagate_at_launch = true
  }

  # Health check via ALB so the ASG replaces truly unhealthy instances
  health_check_type         = "ELB"
  health_check_grace_period = 120
}

# ── Backend Tier Launch Template ─────────────────────────────────────────────────
# Injects full_name into backend.sh so it appears in the API response page
resource "aws_launch_template" "backend" {
  name_prefix   = "lab007-backend-"
  image_id      = data.aws_ami.amazon.id
  instance_type = var.instance_type
  key_name      = var.key_name

  iam_instance_profile {
    name = aws_iam_instance_profile.profile.name
  }

  vpc_security_group_ids = [aws_security_group.backend.id]

  user_data = base64encode(templatefile("userdata/backend.sh", {
    full_name = var.full_name
  }))

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "lab007-backend" }
  }
}

# ── Backend Tier Auto Scaling Group ──────────────────────────────────────────────
resource "aws_autoscaling_group" "backend" {
  name                = "lab007-backend-asg"
  min_size            = 1
  max_size            = 3
  desired_capacity    = 2
  vpc_zone_identifier = aws_subnet.private[*].id

  launch_template {
    id      = aws_launch_template.backend.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "lab007-backend"
    propagate_at_launch = true
  }

  health_check_type         = "ELB"
  health_check_grace_period = 180
}
