resource "aws_instance" "jk_server" {
  ami                         = "${var.host_image_id}"
  instance_type               = "${var.instance_type_server}"
  subnet_id                   = "${var.jenkins_server_subnet}"
  vpc_security_group_ids      = ["${aws_security_group.mit_jk_server.id}"]
  associate_public_ip_address = true
  key_name                    = "mit.ci"
  user_data                   = "${data.template_file.user_data_server.rendered}"
  iam_instance_profile        = "mit-ci"

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 100
    delete_on_termination = true
  }

  tags = {
    Name        = "${var.product}.ci.jk-server"
    product     = "${var.product}"
    service     = "${var.service}"
    environment = "${var.environment}"
  }
}

  resource "aws_eip_association" "eip_association_jk_server" {
  depends_on    = ["aws_instance.jk_server"]
  instance_id   = "${aws_instance.jk_server.id}"
  allocation_id = "${var.allocation_id_jk_server}"
}
