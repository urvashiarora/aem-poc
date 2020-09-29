data "aws_acm_certificate" "jenkins_ctmers" {
  domain   = "*.cicd.ctmers.io"
  statuses = ["ISSUED"]
  most_recent = true
}
