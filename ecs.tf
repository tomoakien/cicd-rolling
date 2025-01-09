#ECSのタスク定義

resource "aws_ecs_task_definition" "task" {
  #タスク定義の名前
  family = "ctn-cicd-hdon"
  #cpu,memoryについて、fargateは必須0.25vcpu
  cpu    = 256
  memory = 1024
  #デフォルトはawsvpc推奨。
  network_mode = "awsvpc"
  #EC2かFARGATEか
  requires_compatibilities = ["FARGATE"]
  #必須。コンテナ定義のリソース
  container_definitions = file("./container_definitions.json")

  #IAMロールを指定
  execution_role_arn = aws_iam_role.ecs_role.arn

  lifecycle {
    ignore_changes = [
      cpu, memory, container_definitions
    ]
  }
}

#クラスターの設定
resource "aws_ecs_cluster" "cluster" {
  name = "ctn-cicd-hdon-cluster"
}

#サービスの設定
resource "aws_ecs_service" "service" {
  name             = "ctn-cicd-hdon-service"
  cluster          = aws_ecs_cluster.cluster.arn
  task_definition  = aws_ecs_task_definition.task.arn
  desired_count    = 2
  launch_type      = "FARGATE"
  platform_version = "1.4.0"

  #ローリングアップデートの設定
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  #ロードバランサーの指定はここで行う
  load_balancer {
    target_group_arn = aws_lb_target_group.alb_tg.arn
    container_name   = "ctn-cicd-hdon-cont"
    container_port   = 80
  }

  network_configuration {
    assign_public_ip = true
    security_groups  = [aws_security_group.sg.id]
    subnets          = [aws_subnet.pub_1.id, aws_subnet.pub_2.id]
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}

