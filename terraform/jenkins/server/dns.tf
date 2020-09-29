resource "aws_route53_record" "cicd_jenkins" {
  depends_on = ["aws_elb.mit_jenkins_loadbalancer"]
  zone_id    = "${data.terraform_remote_state.dns.public_hosted_zone_id}"
  name       = "${var.product}-jenkins.${var.environment}.ctmers.io"
  type       = "A"

  alias {
    name                   = "${aws_elb.mit_jenkins_loadbalancer.dns_name}"
    zone_id                = "${aws_elb.mit_jenkins_loadbalancer.zone_id}"
    evaluate_target_health = true
  }
}
