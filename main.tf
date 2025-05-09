terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }


  backend "s3" {
    bucket = "tfstate-lab-02-infra-us-east-1"
    key    = "jupyter-ecs/terraform.tfstate"
    region = "us-east-2"
  }
}

provider "aws" {
  region = "us-east-2"
}

# Cluster ECS
resource "aws_ecs_cluster" "jupyter_cluster" {
  name = "jupyter-cluster"
}

# Task Definition para o container Jupyter
resource "aws_ecs_task_definition" "jupyter_task" {
  family                   = "jupyter-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 4096
  memory                   = 16384
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  

  container_definitions = jsonencode([{
    name      = "jupyter-container"
    image     = "thisthiago/jupyter:latest"
    cpu       = 4096
    memory    = 16384
    essential = true
    interactive = true,
    tty = true
    "command": [
      "start-notebook.sh",
      "--NotebookApp.token=''",
      "--NotebookApp.password=''"
    ]
    portMappings = [{
      containerPort = 8888
      hostPort      = 8888
      protocol      = "tcp"
    }]
  }])
}

# Serviço ECS para executar a task
resource "aws_ecs_service" "jupyter_service" {
  name            = "jupyter-service"
  cluster         = aws_ecs_cluster.jupyter_cluster.id
  task_definition = aws_ecs_task_definition.jupyter_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public.id]
    security_groups  = [aws_security_group.jupyter_sg.id]
    assign_public_ip = true
  }
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "jupyter-vpc"
  }
}

# Subnet pública
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "jupyter-public-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "jupyter-igw"
  }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "jupyter-public-rt"
  }
}

# Route Table Association
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group
resource "aws_security_group" "jupyter_sg" {
  name        = "jupyter-sg"
  description = "Allow access to Jupyter"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 8888
    to_port     = 8888
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jupyter-sg"
  }
}

# IAM Role para execução de tasks ECS
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}