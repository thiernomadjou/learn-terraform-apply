# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "aws" {
  region = var.region
}

provider "random" {}

provider "time" {}

# Data listing availability zones
data "aws_availability_zones" "available" {}

#Define the VPC 
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name        = var.vpc_name
    Environment = "demo_environment"
    Terraform   = "true"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 1)
  availability_zone = tolist(data.aws_availability_zones.available.names)[0]

  tags = {
    Name      = "private_subnet_1"
    Terraform = "true"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "random_pet" "instance" {
  length = 2
}

resource "aws_instance" "main" {
  count = 3

  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  subnet_id = aws_subnet.private_subnet.id

  tags = {
    Name  = "${random_pet.instance.id}-${count.index}"
    Owner = "${var.project_name}-tutorial"
  }
}

resource "aws_s3_bucket" "example" {
  tags = {
    Name  = "Example Bucket"
    Owner = "${var.project_name}-tutorial"
  }
}

resource "aws_s3_object" "example" {
  bucket = aws_s3_bucket.example.bucket

  key    = "README.md"
  source = "./README.md"

  etag = filemd5("./README.md")
}
