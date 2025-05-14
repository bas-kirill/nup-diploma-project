###############################################################################
#  Terraform — инфраструктура для бенчмарка mc mirror
###############################################################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

variable "instance_type" {
  description = "EC2 instance type (8 vCPU / 16 GiB / up-to-10 Gbps)"
  default     = "c5.2xlarge"
}

data "aws_availability_zones" "this" {}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "image-id"
    values = ["ami-0934107f9c8c5e9cd"]
  }
}

# IAM
data "aws_iam_policy_document" "assume_ec2" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "bench_role" {
  name               = "mcmirror-maxfilecount-bench-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.assume_ec2.json
}

resource "aws_iam_role_policy_attachment" "s3_full_attach" {
  role       = aws_iam_role.bench_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "cw_agent_attach" {
  role       = aws_iam_role.bench_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "bench_profile" {
  name = "mcmirror-maxfilecount-bench-instance-profile"
  role = aws_iam_role.bench_role.name
}

# Networking
resource "aws_vpc" "workload" {
  cidr_block           = "10.14.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "mcmirror-maxfilecount-vpc"
  }
}

resource "aws_internet_gateway" "workload" {
  vpc_id = aws_vpc.workload.id

  tags = {
    Name = "mcmirror-maxfilecount-igw"
  }
}

resource "aws_subnet" "workload_public" {
  vpc_id                  = aws_vpc.workload.id
  cidr_block              = "10.14.1.0/24"
  availability_zone       = data.aws_availability_zones.this.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "mcmirror-maxfilecount-public-subnet"
  }
}

resource "aws_route_table" "workload_public" {
  vpc_id = aws_vpc.workload.id

  tags = {
    Name = "mcmirror-maxfilecount-public-rt"
  }
}

resource "aws_route" "workload_public_internet" {
  route_table_id         = aws_route_table.workload_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.workload.id
}

resource "aws_route_table_association" "workload_public_assoc" {
  subnet_id      = aws_subnet.workload_public.id
  route_table_id = aws_route_table.workload_public.id
}

# Security Group
resource "aws_security_group" "workload_sg" {
  name        = "mcmirror-maxfilecount-sg"
  vpc_id      = aws_vpc.workload.id
  description = "Allow all ingress/egress (mc mirror benchmark)"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# CloudWatch
resource "aws_cloudwatch_log_group" "workload_logs" {
  name              = "/bench/mcmirror-maxfilecount"
  retention_in_days = 30
}

# EC2
resource "aws_instance" "workload" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.workload_public.id
  vpc_security_group_ids      = [aws_security_group.workload_sg.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.bench_profile.name
  instance_initiated_shutdown_behavior = "terminate"

  root_block_device {
    volume_size = 200
    volume_type = "gp3"
  }

  user_data = <<-USERDATA
    #!/bin/bash
    set -e
    exec > >(tee -a /var/log/user-data.log) 2>&1
    apt update -y && apt upgrade -y
    apt install -y git unzip bc linux-tools-common curl binutils
    apt install -y linux-tools-common linux-tools-generic
    curl -sS "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip
    unzip awscliv2.zip && sudo ./aws/install
    aws s3 cp "s3://diploma-scripts/bootstrapMcmirrorMaxFileCount.sh" "/tmp/bootstrapMcmirrorMaxFileCount.sh"
    chmod +x "/tmp/bootstrapMcmirrorMaxFileCount.sh"
    /tmp/bootstrapMcmirrorMaxFileCount.sh
  USERDATA

  tags = {
    Name = "mcmirror-maxfilecount-benchmark"
  }
}

# Outputs
output "public_ip" {
  value = aws_instance.workload.public_ip
}

output "vpc_id" {
  value = aws_vpc.workload.id
}
