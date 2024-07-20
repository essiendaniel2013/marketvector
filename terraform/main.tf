resource "aws_ecs_service" "marketvector_app" {
  name            = var.service_name
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.marketvector_app.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"
  platform_version = "LATEST"

  network_configuration {
    subnets         = var.subnet_ids
    security_groups = [aws_security_group.ecs.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = "marketvector-app"
    container_port   = var.container_port
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  depends_on = [aws_lb_listener.http]

}
[ec2-user@ip-172-31-16-155 terraform]$ cat main.tf 
provider "aws" {
  region = "us-east-1"
}

resource "aws_ecs_cluster" "main" {  
  name = var.cluster_name
}

resource "aws_security_group" "ecs" {
  name_prefix = "ecs-sg-"
  description = "ECS security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "main" {
  name               = "marketvector-lb"
[ec2-user@ip-172-31-16-155 terraform]$ ls
Jenkinsfile  backend.tf  ecs_service.tf  main.tf  output.tf  task_definition.tf  variables.tf
[ec2-user@ip-172-31-16-155 terraform]$ cat main.tf 
provider "aws" {
  region = "us-east-1"
}

resource "aws_ecs_cluster" "main" {
  name = var.cluster_name
}

resource "aws_security_group" "ecs" {
  name_prefix = "ecs-sg-"
  description = "ECS security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "main" {
  name               = "marketvector-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs.id]
  subnets            = var.subnet_ids

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "main" {
  name        = "marketvector-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
  depends_on = [aws_lb_target_group.main]
}

resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/marketvector-app"
  retention_in_days = 30
}
