terraform {
  backend "s3" {
    bucket                  = "japi-terraform-s3-state"
    key                     = "my-terraform-project"
    region                  = "eu-north-1"
    shared_credentials_file = "~/.aws/credentials"
  }
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "ec2_k8s_sg" {
  description = "ec2 kubernetes sg"
  dynamic "ingress" {
    for_each = var.ingress_sg_rules
    content {
      cidr_blocks      = lookup(ingress.value, "cidr_blocks", [])
      description      = lookup(ingress.value, "description", "")
      from_port        = ingress.value.from_port
      ipv6_cidr_blocks = lookup(ingress.value, "ipv6_cidr_blocks", [])
      prefix_list_ids  = lookup(ingress.value, "prefix_list_ids", [])
      protocol         = lookup(ingress.value, "protocol", "tcp")
      security_groups  = lookup(ingress.value, "security_groups", [])
      self             = ingress.value.self
      to_port          = ingress.value.to_port
    }
  }
  egress = [
    {
      cidr_blocks = [
        "0.0.0.0/0",
      ]
      description      = null
      from_port        = 0
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "-1"
      security_groups  = []
      self             = true
      to_port          = 0
    },
  ]
  name   = "ec2_k8s_sg"
  vpc_id = data.aws_vpc.default.id
}

resource "aws_instance" "master" {
  ami           = "ami-08eb150f611ca277f"
  instance_type = "t3.micro"
  key_name      = "japi-test"
  vpc_security_group_ids      = [aws_security_group.ec2_k8s_sg.id]
  associate_public_ip_address = true
  tags = {
    Name = "master"
  }
  user_data = var.ec2_master_user_data
  count = 1
  provisioner "local-exec" {
    command = <<EOT
      sleep 130
      scp -i ~/.ssh/japi-test.pem -o "StrictHostKeyChecking no" ubuntu@${self.public_ip}:/tmp/join_cluster.json ./join_cluster.json
    EOT
  }
}

locals {
  jcommand = jsondecode(file("./join_cluster.json"))
}

resource "aws_instance" "worker" {
  ami           = "ami-08eb150f611ca277f"
  instance_type = "t3.micro"
  key_name      = "japi-test"
  vpc_security_group_ids      = [aws_security_group.ec2_k8s_sg.id]
  associate_public_ip_address = true
  tags = {
    Name = "worker${count.index + 1 }"
  }
  user_data_replace_on_change = true
  user_data = var.ec2_worker_user_data
  count = var.number_of_workers
  metadata_options {
    http_endpoint = "enabled"
    instance_metadata_tags = "enabled"
  }
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/japi-test.pem")
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sleep 120",
      "sudo ${local.jcommand.join_command}"
    ]
  }
}

output "priv_ip" {
  value = aws_instance.master.*.private_ip
}

output "join_cluster" {
  value = local.jcommand.join_command
}

#output "virtual_network_name_values_function" {
#  value = values({for sg_rule in var.sg_rules : sg_rule.from_port => sg_rule.to_port })
#}