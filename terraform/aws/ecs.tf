resource "aws_ecs_cluster" "main" {
  name = "ads-platform-cluster"
}

resource "aws_ecs_task_definition" "app" {
  family                   = "ads-platform-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = 256
  memory = 512

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name  = "ads-platform"
      image = "940531747584.dkr.ecr.us-east-1.amazonaws.com/ads-platform:latest"

      essential = true

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app.name
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }

      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
        }
      ]

      environment = [
        {
          name  = "APP_ENV"
          value = "production"
        },
        {
          name  = "APP_HOST"
          value = "0.0.0.0"
        },
        {
          name  = "APP_PORT"
          value = "8000"
        },
        {
          name  = "DATABASE_URL"
          value = "postgresql://ads_user:${var.db_password}@${aws_db_instance.postgres.address}:5432/ads_platform"
        }
      ]
    }
  ])
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/ads-platform"
  retention_in_days = 7
}