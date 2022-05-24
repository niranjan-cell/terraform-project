ubuntu@ip-172-31-25-133:~/terr$ ls
main.tf  myKey.pem  provider.tf  terraform.tfstate  variables.tf
ubuntu@ip-172-31-25-133:~/terr$ cat provider.tf
terraform {
 required_providers {
   aws = {
     source  = "hashicorp/aws"
     version = "~> 3.0"
   }
 }
}

provider "aws" {
 region = var.region
}

ubuntu@ip-172-31-25-133:~/terr$ cat variables.tf


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


ubuntu@ip-172-31-25-133:~/terr$ cat main.tf
#Create the VPC
resource "aws_vpc" "Main" {
  cidr_block       = var.main_vpc_cidr
  instance_tenancy = "default"
  enable_dns_hostnames = true
}
# Create Internet Gateway and attach it to VPC
resource "aws_internet_gateway" "IGW" {
  vpc_id =  aws_vpc.Main.id
}
#Create two Public Subnets.
resource "aws_subnet" "publicsubnet1" {
  vpc_id =  aws_vpc.Main.id
  cidr_block = "${var.public_subnet1}"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public1"
  }
 }

resource "aws_subnet" "publicsubnet2" {
  vpc_id =  aws_vpc.Main.id
  cidr_block = "${var.public_subnet2}"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "public2"
  }
 }


#Creating two Private Subnet
resource "aws_subnet" "privatesubnet1" {
  vpc_id =  aws_vpc.Main.id
  cidr_block = "${var.private_subnet1}"
  availability_zone = "us-east-1a"
  tags = {
    Name = "private1"
  }
}

resource "aws_subnet" "privatesubnet2" {
  vpc_id =  aws_vpc.Main.id
  cidr_block = "${var.private_subnet2}"
  availability_zone = "us-east-1b"
  tags = {
    Name = "private2"
  }
}
#Route table for Public Subnet's
resource "aws_route_table" "PublicRT" {
  vpc_id =  aws_vpc.Main.id
  route {
  cidr_block = "0.0.0.0/0"               # Traffic from Public Subnet reaches Internet via Internet Gatewa
  gateway_id = aws_internet_gateway.IGW.id
  }
}

#Route table Association with Public Subnet's
resource "aws_route_table_association" "PublicRTassociation" {
  subnet_id = aws_subnet.publicsubnet1.id
  route_table_id = aws_route_table.PublicRT.id
}

resource "aws_route_table_association" "PublicRTassociation1" {
  subnet_id = aws_subnet.publicsubnet2.id
  route_table_id = aws_route_table.PublicRT.id
}
#create a key pair and save it to local computer
resource "tls_private_key" "my_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "deployer" {
  key_name   = "efskey"       # Create a "myKey" to AWS!!
  public_key = tls_private_key.my_key.public_key_openssh

  provisioner "local-exec" { # Create a "myKey.pem" to your computer!!
    command = "echo '${tls_private_key.my_key.private_key_pem}' > myKey.pem"
  }
}

#creates ec2 instance
resource "aws_instance" "demo" {
  ami = var.ami
  instance_type = var.type
  subnet_id = aws_subnet.publicsubnet1.id
  key_name = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.efs.id, aws_security_group.sg.id]
  tags = {
    Name = "Demo System"
  }
}

#creates security groups
resource "aws_security_group" "sg" {
  name        = "webserver-firewall"
  description = "Security group for  instances"
  vpc_id      = aws_vpc.Main.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }


}

resource "aws_security_group" "efs" {
  name = "sg for efs"
  description = "Security group for efs"
  vpc_id      = aws_vpc.Main.id
  ingress {
    security_groups = [aws_security_group.sg.id]
    from_port = 2049
    to_port = 2049
     protocol = "tcp"
  }

  egress {
    security_groups = [aws_security_group.sg.id]
    from_port = 0
    to_port = 0
    protocol = "-1"
  }

}

#creates db subnet group
resource "aws_db_subnet_group" "default" {
  name        = "subnet for db"
  description = "Private subnets for RDS instance"
  subnet_ids  = [aws_subnet.privatesubnet1.id, aws_subnet.privatesubnet2.id]
}

# creates database
resource "aws_db_instance" "Main" {
# Allocating the storage for database instance.
  allocated_storage    = 10
# Declaring the database engine and engine_version
  engine               = var.engine
  engine_version       = var.engine_version
# Declaring the instance class
  instance_class       = var.instance_class
  name                 = var.name
# User to connect the database instance
  username             = var.username
# Password to connect the database instance
  password             = var.password
  parameter_group_name = var.parameter_group_name
  vpc_security_group_ids = ["${aws_security_group.sg.id}"]
  db_subnet_group_name = aws_db_subnet_group.default.id
}


#creates efs
resource "aws_efs_file_system" "efs" {
  creation_token = "efs"
  performance_mode = "generalPurpose"
  throughput_mode = "bursting"
  encrypted = "true"
  tags = {
  Name = "EFS"
  }
}

resource "aws_efs_mount_target" "efs-mt" {
  file_system_id = aws_efs_file_system.efs.id
  subnet_id = aws_subnet.privatesubnet1.id
  security_groups = [aws_security_group.efs.id]
}

#attach efs to ec2 instance
resource "null_resource" "configure_nfs" {
  depends_on = [aws_efs_mount_target.efs-mt]
  connection {
    type     = "ssh"
    user     = "ubuntu"
    host     = aws_instance.demo.public_ip
    private_key = tls_private_key.my_key.private_key_pem
 }
  provisioner "remote-exec" {
  inline = [
    "sudo apt update",
    "sudo apt install apache2 -y",
    "sudo systemctl start apache2",
    "sudo systemctl enable apache2",
    "sudo apt install nfs-common -y -q",
# Mounting Efs
    "sudo mount -t nfs -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${aws_efs_file_system.efs.dns_name}:/  /var/www/html",
# Making Mount Permanent
    "sudo chmod 666 /etc/fstab",
    "sudo echo '${aws_efs_file_system.efs.dns_name}:/ /var/www/html nfs4 defaults,_netdev 0 0' >> /etc/fstab",
  ]
 }
}

