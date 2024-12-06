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
  dynamic ingress {
    for_each = var.sg_rules
    content {
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
      from_port = ingress.value.from_port
      ipv6_cidr_blocks = ingress.value.ipv6_cidr_blocks
      prefix_list_ids = ingress.value.prefix_list_ids
      protocol = ingress.value.protocol
      security_groups = ingress.value.security_groups
      self = ingress.value.self
      to_port = ingress.value.to_port
    }
  }
    description = "ec2 kubernetes sg"
    egress      = [
        {
            cidr_blocks      = [
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
    name        = "ec2_k8s_sg"
    vpc_id      = data.aws_vpc.default.id
}

resource "aws_instance" "master" {
  ami           = "ami-08eb150f611ca277f"
  instance_type = "t3.micro"
  key_name      = "japi-test"

  # Interfejs sieciowy i grupa bezpieczeństwa
  vpc_security_group_ids = [aws_security_group.ec2_k8s_sg.id]
  associate_public_ip_address = true


  # Tagi
  tags = {
    Name = "master"
  }
  
#  user_data_base64 = "IyEvYmluL2Jhc2gKc3VkbyBzd2Fwb2ZmIC1hCnN1ZG8gY2F0IDw8RU9GIHwgc3VkbyB0ZWUgL2V0Yy9zeXNjdGwuZC9rOHMuY29uZgpuZXQuaXB2NC5pcF9mb3J3YXJkID0gMQpFT0YKc3VkbyBjYXQgPDxFT0YgfCBzdWRvIHRlZSAvZXRjL21vZHVsZXMtbG9hZC5kL2NvbnRhaW5lcmQuY29uZgpvdmVybGF5CmJyX25ldGZpbHRlcgpFT0YKc3VkbyBob3N0bmFtZWN0bCBzZXQtaG9zdG5hbWUgbWFzdGVyCnN1ZG8gYXB0LWdldCB1cGRhdGUKc3VkbyBhcHQtZ2V0IGluc3RhbGwgLXkgYXB0LXRyYW5zcG9ydC1odHRwcyBjYS1jZXJ0aWZpY2F0ZXMgY3VybCBncGcgY29udGFpbmVyZApzdWRvIG1rZGlyIC1wIC9ldGMvYXB0L2tleXJpbmdzLwpjdXJsIC1mc1NMIGh0dHBzOi8vcGtncy5rOHMuaW8vY29yZTovc3RhYmxlOi92MS4zMS9kZWIvUmVsZWFzZS5rZXkgfCBzdWRvIGdwZyAtLWRlYXJtb3IgLW8gL2V0Yy9hcHQva2V5cmluZ3Mva3ViZXJuZXRlcy1hcHQta2V5cmluZy5ncGcKZWNobyAnZGViIFtzaWduZWQtYnk9L2V0Yy9hcHQva2V5cmluZ3Mva3ViZXJuZXRlcy1hcHQta2V5cmluZy5ncGddIGh0dHBzOi8vcGtncy5rOHMuaW8vY29yZTovc3RhYmxlOi92MS4zMS9kZWIvIC8nIHwgc3VkbyB0ZWUgL2V0Yy9hcHQvc291cmNlcy5saXN0LmQva3ViZXJuZXRlcy5saXN0CnN1ZG8gYXB0LWdldCB1cGRhdGUKc3VkbyBhcHQtZ2V0IGluc3RhbGwgLXkga3ViZWxldCBrdWJlYWRtIGt1YmVjdGwKc3VkbyBzeXN0ZW1jdGwgZW5hYmxlIC0tbm93IGt1YmVsZXQKc3VkbyBta2RpciAvZXRjL2NvbnRhaW5lcmQvCnN1ZG8gY29udGFpbmVyZCBjb25maWcgZGVmYXVsdCA+IC9ldGMvY29udGFpbmVyZC9jb25maWcudG9tbApzdWRvIHNlZCAtaSAncy8gICAgICAgICAgICBTeXN0ZW1kQ2dyb3VwID0gZmFsc2UvICAgICAgICAgICAgU3lzdGVtZENncm91cCA9IHRydWUvJyAvZXRjL2NvbnRhaW5lcmQvY29uZmlnLnRvbWwKc3VkbyBzeXNjdGwgLS1zeXN0ZW0Kc3VkbyBtb2Rwcm9iZSBicl9uZXRmaWx0ZXIKc3VkbyBzeXN0ZW1jdGwgcmVzdGFydCBjb250YWluZXJkClRPS0VOPSQoY3VybCAtWCBQVVQgImh0dHA6Ly8xNjkuMjU0LjE2OS4yNTQvbGF0ZXN0L2FwaS90b2tlbiIgLUggIlgtYXdzLWVjMi1tZXRhZGF0YS10b2tlbi10dGwtc2Vjb25kczogMjE2MDAiKQpJTlNUQU5DRV9JUD0kKGN1cmwgLXMgLUggIlgtYXdzLWVjMi1tZXRhZGF0YS10b2tlbjogJFRPS0VOIiBodHRwOi8vMTY5LjI1NC4xNjkuMjU0L2xhdGVzdC9tZXRhLWRhdGEvbG9jYWwtaXB2NCkKc3VkbyBrdWJlYWRtIGluaXQgLS1hcGlzZXJ2ZXItYWR2ZXJ0aXNlLWFkZHJlc3M9JElOU1RBTkNFX0lQIC0taWdub3JlLXByZWZsaWdodC1lcnJvcnM9TWVtCm1rZGlyIC1wICRIT01FLy5rdWJlCnN1ZG8gY3AgLWkgL2V0Yy9rdWJlcm5ldGVzL2FkbWluLmNvbmYgJEhPTUUvLmt1YmUvY29uZmlnCnN1ZG8gY2hvd24gJChpZCAtdSk6JChpZCAtZykgJEhPTUUvLmt1YmUvY29uZmlnCmt1YmVjdGwgYXBwbHkgLWYgaHR0cHM6Ly9yZXdlYXZlLmF6dXJld2Vic2l0ZXMubmV0L2s4cy92MS4zMS9uZXQueWFtbA=="
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

  # Interfejs sieciowy i grupa bezpieczeństwa
  vpc_security_group_ids = [aws_security_group.ec2_k8s_sg.id]
  associate_public_ip_address = true


  # Tagi
  tags = {
    Name = "worker"
  }
  
  user_data = var.ec2_worker_user_data

  count = 1
  connection {
      type     = "ssh"
      user     = "ubuntu"
      private_key = file("~/.ssh/japi-test.pem")
      host = self.public_ip
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