resource "aws_security_group" "mit_jk_server" {
  # depends_on = ""
  name   = "${var.product}.${var.service}.${var.server_name}"
  vpc_id = "${var.jenkins_server_vpc}"

  tags {
    Name        = "${var.product}.${var.service}.${var.server_name}"
    product     = "${var.product}"
    service     = "${var.service}"
    environment = "${var.environment}"
  }
}

resource "aws_security_group_rule" "mit_ci_jk_server_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.mit_jk_server.id}"
  description       = "External Outbound Access"
}

resource "aws_security_group_rule" "mit_ci_jk_server_ingress_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["${var.cidr_block["bifrost"]}"]
  security_group_id = "${aws_security_group.mit_jk_server.id}"
  description       = "Bifrost SSH Access"
}

resource "aws_security_group_rule" "mit_ci_jk_server_ingress_elb" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.mit_ci_jk_elb.id}"
  security_group_id        = "${aws_security_group.mit_jk_server.id}"
  description              = "ELB access to server"
}

resource "aws_security_group" "mit_ci_jk_elb" {
  name   = "${var.product}.${var.service}.jenkins_elb_sg"
  vpc_id = "${var.jenkins_server_vpc}"

  tags {
    Name        = "${var.product}.${var.service}.jenkins_elb_sg"
    product     = "${var.product}"
    service     = "${var.service}"
    environment = "${var.environment}"
  }
}

resource "aws_security_group_rule" "mit_ci_jk_elb_ingress_access" {
  type      = "ingress"
  from_port = 443
  to_port   = 443
  protocol  = "tcp"

  cidr_blocks = "${compact(concat(
    var.cidr_block["bifrost"],
  var.cidr_block["sergeinet2"]))}"

  security_group_id = "${aws_security_group.mit_ci_jk_elb.id}"
  description       = "User Website Access"
}


resource "aws_security_group_rule" "mit_ci_elb_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.mit_ci_jk_elb.id}"
  description       = "External Outbound Access"
}
