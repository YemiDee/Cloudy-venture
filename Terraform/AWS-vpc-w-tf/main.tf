# terraform {
#   backend “s3” {
#     bucket = “devops-gwin-state”
#     key    = “path/to/my/state”
#     region = “ca-central-1"
#   }
# }

#create VPC

resource "aws_vpc" "proj-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    "Name" = "proj-VPC"
  }
}
#Create 2 public subnets and 2 private subnets, a pair of public and private SN in same AZs

#Create VPC Pub subnet 01
resource "aws_subnet" "proj-vpc-PubSN01" {
  vpc_id            = aws_vpc.proj-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "proj-vpc-Pub-SN01"
  }
}

#Create VPC Pub subnet 02
resource "aws_subnet" "proj-vpc-PubSN02" {
  vpc_id            = aws_vpc.proj-vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "proj-vpc-Pub-SN02"
  }
}

#Create VPC Private subnet 01
resource "aws_subnet" "proj-vpc-PrvSN01" {
  vpc_id            = aws_vpc.proj-vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "proj-vpc-Prv-SN01"
  }
}

#Create VPC Private subnet 02
resource "aws_subnet" "proj-vpc-PrvSN02" {
  vpc_id            = aws_vpc.proj-vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "proj-vpc-Prv-SN02"
  }
}

#create internet gateway
resource "aws_internet_gateway" "proj-vpc-igw" {
  vpc_id = aws_vpc.proj-vpc.id
  tags = {
    Name = "proj-vpc-igw"
  }
}

#create NAT gateway
resource "aws_nat_gateway" "proj-vpc-NGW" {
  allocation_id = aws_eip.proj-vpc-NGW.id
  subnet_id     = aws_subnet.proj-vpc-PubSN01.id

  tags = {
    Name = "proj-vpc-NGW"
  }

  # depends_on = [aws_internet_gateway.proj-vpc-igw]
}

#create elastic IP
resource "aws_eip" "proj-vpc-NGW" {
  depends_on = [aws_internet_gateway.proj-vpc-igw]
}

#create public route table
resource "aws_route_table" "projvpc-pub-RT" {
  vpc_id = aws_vpc.proj-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.proj-vpc-igw.id
  }

  tags = {
    Name = "projvpc-pub-RT"
  }
}

#create private route table
resource "aws_route_table" "projvpc-prv-RT" {
  vpc_id = aws_vpc.proj-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.proj-vpc-NGW.id
  }

  tags = {
    Name = "projvpc-prv-RT"
  }
}

#create route table association pub SN01
resource "aws_route_table_association" "rta-pubsn01" {
  subnet_id      = aws_subnet.proj-vpc-PubSN01.id
  route_table_id = aws_route_table.projvpc-pub-RT.id
}

#create route table association pub SN02
resource "aws_route_table_association" "rta-pubsn02" {
  subnet_id      = aws_subnet.proj-vpc-PubSN02.id
  route_table_id = aws_route_table.projvpc-pub-RT.id
}

#create route table association prv SN01
resource "aws_route_table_association" "rta-prvsn01" {
  subnet_id      = aws_subnet.proj-vpc-PrvSN01.id
  route_table_id = aws_route_table.projvpc-prv-RT.id
}

#create route table association prv SN02
resource "aws_route_table_association" "rta-prvsn02" {
  subnet_id      = aws_subnet.proj-vpc-PrvSN02.id
  route_table_id = aws_route_table.projvpc-prv-RT.id
}

#create frontend security group
resource "aws_security_group" "projvpc-frontendSG" {
  name        = "projvpc-frontendSG"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.proj-vpc.id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
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
  tags = {
    Name = "projvpc-frontendSG"
  }
}

#create backend security group
resource "aws_security_group" "projvpc-backendSG" {
  name        = "projvpc-backendSG"
  description = "Allow frontend inbound traffic"
  vpc_id      = aws_vpc.proj-vpc.id

  ingress {
    description = "MYSQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "projvpc-backendSG"
  }
}

#creats S3 bucket for media
resource "aws_s3_bucket" "projvpc-med-buc" {
  bucket        = "projvpc-med-buc"
  force_destroy = true
  tags = {
    Name        = "projvpc-med-buc"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_acl" "projvpc-med-buc-acl" {
  bucket = aws_s3_bucket.projvpc-med-buc.id
  acl    = "public-read"
}

#update bucket policy
resource "aws_s3_bucket_policy" "projvpc-med-pol" {
  bucket = aws_s3_bucket.projvpc-med-buc.id
  policy = jsonencode({
    Id = "projvpcmedpol"
    Statement = [
      {
        Action = ["s3:GetObject", "s3:GetObjectVersion"]
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Resource = "arn:aws:s3:::projvpc-med-buc/*"
        Sid      = "PublicReadGetObject"
      }
    ]
    Version = "2012-10-17"
  })
}

resource "aws_key_pair" "prj-vpc-key" {
  key_name = "prj-vpc-key"
  public_key = file(var.prj-vpc-key)
}
#provision an ec2 instance
resource "aws_instance" "projvpc-web" {
  ami                         = var.ami
  instance_type               = var.instance-ami
  vpc_security_group_ids      = [aws_security_group.projvpc-frontendSG.id]
  subnet_id                   = aws_subnet.proj-vpc-PubSN01.id
  associate_public_ip_address = true
  key_name                    = "prj-vpc-key"
  user_data                   = <<-EOF
  #!/bin/bash
  #sudo yum update -y
  sudo yum install httpd -y
  sudo service httpd start
  sudo chkconfig httpd on
  cd /var/www/html
  echo "<html><h1>This is Apache Web Server 01</h1></html>" > index.html
  sudo yum install mysql -y
  EOF
  tags = {
    Name = "HelloWorld"
  }
}

#complete for relational SQL database server
#provision instance for this and attach to private subnet