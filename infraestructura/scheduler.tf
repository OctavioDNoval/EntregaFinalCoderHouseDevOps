locals {
  shutdown_schedule = var.environment == "dev" ? true : false
}

resource "aws_iam_role" "scheduler" {
  count = local.shutdown_schedule ? 1 : 0
  name  = "${var.project_name}-ec2-scheduler"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "scheduler.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = local.common_tags
}

resource "aws_iam_role_policy" "scheduler" {
  count = local.shutdown_schedule ? 1 : 0
  name  = "${var.project_name}-ec2-start-stop"
  role  = aws_iam_role.scheduler[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ec2:StartInstances",
        "ec2:StopInstances",
        "ec2:DescribeInstances"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_scheduler_schedule" "start_ec2" {
  count = local.shutdown_schedule ? 1 : 0
  name  = "${var.project_name}-start-weekdays"
  schedule_expression         = "cron(0 8 ? * MON-FRI *)"
  schedule_expression_timezone = "America/Argentina/Buenos_Aires"
  flexible_time_window {
    mode = "OFF"
  }
  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:startInstances"
    role_arn = aws_iam_role.scheduler[0].arn
    input = jsonencode({
      InstanceIds = [module.compute.instance_id]
    })
  }
}

resource "aws_scheduler_schedule" "stop_ec2" {
  count = local.shutdown_schedule ? 1 : 0
  name  = "${var.project_name}-stop-weekdays"
  schedule_expression         = "cron(0 20 ? * MON-FRI *)"
  schedule_expression_timezone = "America/Argentina/Buenos_Aires"
  flexible_time_window {
    mode = "OFF"
  }
  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:stopInstances"
    role_arn = aws_iam_role.scheduler[0].arn
    input = jsonencode({
      InstanceIds = [module.compute.instance_id]
    })
  }
}
