

variable "region" {
 default = "us-east-1"
 description = "AWS Region"
}

variable "ami" {
 default = "ami-04505e74c0741db8d"
 description = "Amazon Machine Image ID for Ubuntu Server 20.04"
}

variable "type" {
 default = "t2.micro"
 description = "Size of VM"
}

variable "main_vpc_cidr" {
  default = "10.0.0.0/16"
  description = "vpc cidr block"
}
variable "public_subnet1" {
  default = "10.0.0.0/24"
  description = "public subnet1"
}

variable "public_subnet2" {
  default = "10.0.2.0/24"
  description = "public subnet2"
}

variable "private_subnet1" {
  default = "10.0.1.0/24"
  description = "private subnet1"
}

variable "private_subnet2" {
  default = "10.0.3.0/24"
  description = "private subnet2"
}

variable "engine" {
  default = "mysql"
}
variable "engine_version" {
  default = "5.7"
}
variable "instance_class" {
  default = "db.t2.micro"
}
variable "name"  {
  default = "mydb"
}
variable "username" {
  default = "root"
}
variable "password" {
  default = "rootroot"
}
variable "parameter_group_name" {
  default = "default.mysql5.7"
}

