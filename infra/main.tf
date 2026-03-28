#############################################################################################
# PROVIDER
#############################################################################################
provider "aws" {
  region = "ca-central-1"
}

#############################################################################################
# IAM ROLE (FARGATE + ECR)
#############################################################################################
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

#############################################################################################
# ECS CLUSTER
#############################################################################################
resource "aws_ecs_cluster" "app_cluster" {
  name = "${var.app_name}_ecs_cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

#############################################################################################
# ECS TASK DEFINITION
#############################################################################################
resource "aws_ecs_task_definition" "app_taskd" {
  family                   = "${var.app_name}_task_definition"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_execution_role_policy
  ]

  container_definitions = jsonencode([
    {
      name      = "${var.app_name}_container"
      image     = var.image_uri
      essential = true

      portMappings = [
        {
          containerPort = 5000
        }
      ]
    }
  ])
}

#############################################################################################
# SECURITY GROUPS
#############################################################################################

# ALB SG (PUBLIC)
resource "aws_security_group" "alb_sg" {
  name   = "${var.app_name}_alb_sg"
  vpc_id = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "alb_inbound" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "alb_outbound" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# ECS SG (PRIVATE)
resource "aws_security_group" "ecs_sg" {
  name   = "${var.app_name}_ecs_sg"
  vpc_id = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "ecs_inbound" {
  security_group_id            = aws_security_group.ecs_sg.id
  referenced_security_group_id = aws_security_group.alb_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 5000
  to_port                      = 5000
}

resource "aws_vpc_security_group_egress_rule" "ecs_outbound" {
  security_group_id = aws_security_group.ecs_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

#############################################################################################
# APPLICATION LOAD BALANCER
#############################################################################################
resource "aws_lb" "app_alb" {
  name               = "applicationlb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [var.subnet01_ID, var.subnet02_ID]
}

#############################################################################################
# TARGET GROUP (IMPORTANT: IP TYPE)
#############################################################################################
resource "aws_lb_target_group" "app_alb_tg" {
  name     = "alb-target-group"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  target_type = "ip"

  health_check {
    path                = "/"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

#############################################################################################
# LISTENER
#############################################################################################
resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_alb_tg.arn
  }
}

#############################################################################################
# ECS SERVICE
#############################################################################################
resource "aws_ecs_service" "app_service" {
  name            = "${var.app_name}_ecs_service"
  cluster         = aws_ecs_cluster.app_cluster.id
  task_definition = aws_ecs_task_definition.app_taskd.arn
  desired_count   = 3
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [var.subnet01_ID, var.subnet02_ID]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app_alb_tg.arn
    container_name   = "${var.app_name}_container"
    container_port   = 5000
  }

  depends_on = [aws_lb_listener.alb_listener]
}
