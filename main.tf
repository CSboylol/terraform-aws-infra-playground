terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.11"
    }
  }
}

variable "region" {
  default = "us-east-1"
}

provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "labs-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "labs-public-subnet"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "labs-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "labs-public-rt"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "sg" {
  name_prefix = "tf-ssh-sg-"
  description = "Allow SSH inbound (lab only)"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Lab-only: restrict in real usage
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_instance" "vm" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t2.micro"

  subnet_id = aws_subnet.public.id

  vpc_security_group_ids = [
    aws_security_group.sg.id
  ]

  tags = {
    Name = "labs-vm"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "null_resource" "check_public_ip" {
  provisioner "local-exec" {
    command = <<EOT
if [ -z "${aws_instance.vm.public_ip}" ]; then
  echo "ERROR: Public IP address was not assigned." >&2
  exit 1
fi
EOT
  }

  depends_on = [
    aws_instance.vm,
    time_sleep.wait_for_ip
  ]
}


resource "time_sleep" "wait_for_ip" {
  depends_on      = [aws_instance.vm]
  create_duration = "10s"
}

output "vm_public_ip" {
  value       = aws_instance.vm.public_ip
  description = "Public IP address of the VM"

  depends_on = [
    null_resource.check_public_ip
  ]
}

