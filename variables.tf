variable "aws_region" {
  default = "ap-south-1"
}

variable "vpc_cidr" {
  default = "10.0.0.1/16"
}

variable "instance_ami" {
  description = "Amazon Machine Image (AMI) (Mumbai)"
  default     = "ami-02b8269d5e85954ef"
}

variable "instance_type" {
  default = "m7i-flex.large"
}

variable "key_name" {
  description = "Existing EC2 key pair name"
  default     = "nwe-jenkins"
}
