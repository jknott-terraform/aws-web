variable "ami" {
  type = map(string)
  description = "A map of AMIs"
  default = {}
}


variable "instance_type" {
  type = string
  description = "The instance type"
  default = "t2.micro"
}

variable "region" {
  type = string
  description = "The AWS region"
  default = "us-east-1"
}


variable "key_name" {
  type = string
  description = "Name of AWS Key to use"
}

variable "instance_ips" {
  type = list(string)
  description = "The IPs to use for our instances"
  default     = ["10.0.1.20", "10.0.1.21"]
}

variable "owner_tag" {
  type = list(string)
  default = ["team1", "team2"]
}


variable "environment" {
  default = "development"
}

variable "key_path" {
  description = "Place where your ssh key is located"
  default = "/home/user/.ssh/jknott.pem"
}
