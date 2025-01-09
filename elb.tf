#ALBの追加
resource "aws_lb" "alb" {
  name               = "alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.pub_1.id, aws_subnet.pub_2.id]
}

#ALBリスナー追加
resource "aws_lb_listener" "aws_alb_listener_http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }
}

#ターゲットグループ作成
resource "aws_lb_target_group" "alb_tg" {
  name     = "web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id

  #fargateを指定する場合ipを指定
  target_type = "ip"
}


