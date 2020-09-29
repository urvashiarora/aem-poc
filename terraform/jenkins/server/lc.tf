data "template_file" "user_data_server" {
  template = "${file("${path.module}/templates/userdata.sh")}"
}
