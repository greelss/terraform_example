resource "aws_vpc" "aws02-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "${var.prefix_list}vpc"
  }
}

resource "aws_subnet" "aws02-public-subnet" {
  count             = length(var.public_subnet_cidr_block)
  vpc_id            = aws_vpc.aws02-vpc.id
  cidr_block        = var.public_subnet_cidr_block[count.index]
  availability_zone = var.availability_zone[count.index]
  tags = {
    Name = "${var.prefix_list}public-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "aws02-private-subnet" {
  count             = length(var.private_subnet_cidr_block)
  vpc_id            = aws_vpc.aws02-vpc.id
  cidr_block        = var.private_subnet_cidr_block[count.index]
  availability_zone = var.availability_zone[count.index]
  tags = {
    Name = "${var.prefix_list}private-subnet-${count.index + 1}"
  }
}

resource "aws_internet_gateway" "aws02-igw" {
  vpc_id = aws_vpc.aws02-vpc.id
  tags = {
    Name = "${var.prefix_list}igw"
  }
}

resource "aws_eip" "aws02-nat-eip" {
  domain = "vpc"
  tags = {
    Name = "${var.prefix_list}nat-eip"
  }
}

resource "aws_nat_gateway" "aws02-nat-gw" {
  allocation_id = aws_eip.aws02-nat-eip.id
  subnet_id     = aws_subnet.aws02-public-subnet[0].id
  tags = {
    Name = "${var.prefix_list}nat-gw"
  }
}

resource "aws_route_table" "aws02-public-rt" {
  vpc_id = aws_vpc.aws02-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.aws02-igw.id
  }
  tags = {
    Name = "${var.prefix_list}public-rt"
  }
}

resource "aws_route_table_association" "aws02-public-rt-association" {
  count          = length(var.public_subnet_cidr_block)
  subnet_id      = aws_subnet.aws02-public-subnet[count.index].id
  route_table_id = aws_route_table.aws02-public-rt.id
}

resource "aws_route_table" "aws02-private-rt" {
  count = length(var.private_subnet_cidr_block)
  vpc_id = aws_vpc.aws02-vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.aws02-nat-gw.id
  }
  tags = {
    Name = "${var.prefix_list}private-subnet-${count.index + 1}"
  }
}

resource "aws_route_table_association" "aws02-private-rt-association" {
  count          = length(var.private_subnet_cidr_block)
  subnet_id      = aws_subnet.aws02-private-subnet[count.index].id
  route_table_id = aws_route_table.aws02-private-rt[count.index].id
}

resource "aws_security_group" "aws02-ssh-sg" {
  name        = "${var.prefix_list}ssh-sg"
  description = "Allow SSH access"
  vpc_id      = aws_vpc.aws02-vpc.id
  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    }
   ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "aws02-http-sg" {
  name        = "${var.prefix_list}http-sg"
  description = "Allow HTTP access"
  vpc_id      = aws_vpc.aws02-vpc.id
  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]  
 }
}
