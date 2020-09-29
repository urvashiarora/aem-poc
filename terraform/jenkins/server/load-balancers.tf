resource "aws_elb" "mit_jenkins_loadbalancer" {
  name     = "${var.product}-${var.service}-jenkins"
  internal = false

  security_groups = [
    "${aws_security_group.mit_ci_jk_elb.id}",
  ]

  subnets      = "${var.cicd_production_subnets}"
  idle_timeout = 60

  listener {
    instance_port      = 8080
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = "${data.aws_acm_certificate.jenkins_ctmers.arn}"    
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    target              = "HTTP:8080/login"
    interval            = 30
  }

  instances = ["${aws_instance.jk_server.id}"]

  tags {
    Name        = "${var.product}.${var.service}.jenkins"
    product     = "${var.product}"
    service     = "${var.service}"
    environment = "${var.environment}"
  }
}
