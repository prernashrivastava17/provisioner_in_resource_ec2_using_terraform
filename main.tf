resource "aws_vpc" "vpc" {
  cidr_block       = "152.40.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "vpc"
  }
}
#create aws_internet_gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "igw"
  }
}
resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "152.40.2.0/24"

  tags = {
    Name = "public_subnet"
  }
}
resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id

  }
  tags = {
    Name = "public_route"
  }
}
#route_table_association
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route.id
}
resource "aws_security_group" "security_group1" {
  name        = "security_group1"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
 egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  tags = {
    Name = "security_group1"
  }
}

resource "aws_key_pair" "key" {
  key_name   = "key"
  public_key = file("${path.module}/key1.pub")
}
resource "aws_instance" "myec2" {
  ami           = "ami-053b0d53c279acc90"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet.id
  key_name =  aws_key_pair.key.key_name
  vpc_security_group_ids  = [aws_security_group.security_group1.id]
  associate_public_ip_address = true

  tags = {
    Name = "myec2"
  }
  provisioner "local-exec" {
    command = "echo ${self.public_ip} >1.txt"
  }
  provisioner "remote-exec"{
     inline = [
        "touch hello.txt"
     ]
  }
  connection {
    type     = "ssh"
    user     = "ubuntu"
    private_key = file("${path.module}/key1")
    host     = self.public_ip
    
  }
   
}

