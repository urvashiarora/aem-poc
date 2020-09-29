variable "account_id" {
  default = "482506117024"
}

variable "environment" {
  default = "cicd"
}

variable "product" {
  default = "mit"
}

variable "service" {
  default = "ci-jk"
}

variable "server_name" {
  default = "jk-server"
}

variable "host_image_id" {
  default = "ami-0fced78e8acad2d16"
}

variable "jenkins_server_vpc" {
  default = "vpc-84b415e1"
}

variable "jenkins_server_subnet" {
  default = "subnet-c4871aa1"
}

variable "cicd_production_subnets" {
  default = ["subnet-c4871aa1", "subnet-0c29937b", "subnet-b630efef"]
}

variable "cidr_block" {
  default = {
    bifrost    = ["10.100.2.19/32", "52.16.89.14/32"]
    sergeinet2 = ["62.172.176.66/32", "87.194.144.188/32"]
  }
}

variable "allocation_id_jk_server" {
  default = "eipalloc-01d260dd778993f93"
}

variable "instance_type_server" {
  default = "t3a.medium"
}
