#Terraform Code

data "template_file" "index" {
  count    = length(var.instance_ips)
  template = file("files/index.html.tpl")

  vars = {
    hostname = "web-${format("%03d", count.index + 1)}"
  }
}



resource "aws_instance" "web" {
  ami           = var.ami[var.region]
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = data.terraform_remote_state.vpc.outputs.public_subnet_id 
  associate_public_ip_address = true
  #user_data     = file("files/bootstrap.sh")
  private_ip    = var.instance_ips[count.index]
  vpc_security_group_ids = [
    aws_security_group.web_host_sg.id
    ]
  
  tags = {
  Name = "web-${format("%03d", count.index + 1)}"
  Owner = element(var.owner_tag, count.index)
  }
  count = var.environment == "production" ? 4 : 2 
  
  connection {
    host        = coalesce(self.public_ip, self.private_ip)
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.key_path)
  }
  
#    provisioner "file" {
#      source = "files/nginx.conf"
#      destination = "/tmp/nginx.conf"
#    }
#
#    provisioner "remote-exec" {
#     inline = [
#       "sudo mv /tmp/nginx.conf /etc/nginx/nginx.conf",
#     ]
#     }


   provisioner "file" {
    content     = element(data.template_file.index[*].rendered, count.index)
    destination = "/tmp/index.html"
    }

  provisioner "remote-exec" {
    script = "files/bootstrap.sh"
    }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/index.html /usr/share/nginx/html/index.html",
    ]
    }

}


resource "aws_elb" "web" {
  name          = "web-elb"
  subnets       = [data.terraform_remote_state.vpc.outputs.public_subnet_id]
  security_groups = [aws_security_group.web_inbound_sg.id]

  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port  = 80
    lb_protocol = "http"
  }
  instances = aws_instance.web[*].id
}

resource "aws_security_group" "web_inbound_sg" {
  name           = "web_inbound"
  description    = "Allow HTTP from anywhere"
  vpc_id         = data.terraform_remote_state.vpc.outputs.vpc_id
  
  ingress {
    from_port    = 80
    to_port      = 80
    protocol     = "tcp"
    cidr_blocks  = ["0.0.0.0/0"]
  }

  ingress {
    from_port    = 8
    to_port      = 0
    protocol     = "icmp"
    cidr_blocks  = ["0.0.0.0/0"]
  }

  egress {
    from_port    = 0
    to_port      = 0
    protocol     = "-1"
    cidr_blocks  = ["0.0.0.0/0"]
  }

}


resource "aws_security_group" "web_host_sg" {
  name        = "web_host"
  description = "Allow SSH & HTTP to web hosts"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from the VPC
  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = [data.terraform_remote_state.vpc.outputs.cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

}
