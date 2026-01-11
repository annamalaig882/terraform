#VPC

resource "aws_vpc" "laza_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "laza-vpc"
  }
}





#Internet Gateway


resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.laza_vpc.id

  tags = {
    Name = "laza-igw"
  }
}




#Subnets
# Public subnet (Web)
resource "aws_subnet" "public_web" {
  vpc_id                  = aws_vpc.laza_vpc.id
  cidr_block              = "10.25.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "laza-public-web"
  }
}




# Private subnets
resource "aws_subnet" "private_app" {
  vpc_id            = aws_vpc.laza_vpc.id
  cidr_block        = "10.25.2.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "laza-private-app"
  }
}

resource "aws_subnet" "private_central" {
  vpc_id            = aws_vpc.laza_vpc.id
  cidr_block        = "10.25.3.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "laza-private-central"
  }
}

resource "aws_subnet" "private_mongo_1" {
  vpc_id            = aws_vpc.laza_vpc.id
  cidr_block        = "10.25.4.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "laza-mongo-1"
  }
}

resource "aws_subnet" "private_mongo_2" {
  vpc_id            = aws_vpc.laza_vpc.id
  cidr_block        = "10.25.5.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "laza-mongo-2"
  }
}

resource "aws_subnet" "private_mongo_3" {
  vpc_id            = aws_vpc.laza_vpc.id
  cidr_block        = "10.25.6.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "laza-mongo-3"
  }
}









#NAT Gateway  EIP


resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_web.id

  tags = {
    Name = "laza-nat"
  }

  depends_on = [aws_internet_gateway.igw]
}















#Route Tables


# Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.laza_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "laza-public-rt"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_web.id
  route_table_id = aws_route_table.public_rt.id
}

# Private Route Table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.laza_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "laza-private-rt"
  }
}

resource "aws_route_table_association" "private_assoc" {
  for_each = {
    app     = aws_subnet.private_app.id
    central = aws_subnet.private_central.id
    mongo1  = aws_subnet.private_mongo_1.id
    mongo2  = aws_subnet.private_mongo_2.id
    mongo3  = aws_subnet.private_mongo_3.id
  }

  subnet_id      = each.value
  route_table_id = aws_route_table.private_rt.id
}





#Security Groups



# Web SG
resource "aws_security_group" "web_sg" {
  vpc_id = aws_vpc.laza_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "web-sg" }
}

# App SG
resource "aws_security_group" "app_sg" {
  vpc_id = aws_vpc.laza_vpc.id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "app-sg" }
}

# Central SG
resource "aws_security_group" "central_sg" {
  vpc_id = aws_vpc.laza_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "central-sg" }
}

# Mongo SG
resource "aws_security_group" "mongo_sg" {
  vpc_id = aws_vpc.laza_vpc.id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  ingress {
    from_port = 27017
    to_port   = 27017
    protocol  = "tcp"
    security_groups = [
      aws_security_group.app_sg.id,
      aws_security_group.central_sg.id
    ]
  }
  ingress {
    from_port = 8501
    to_port   = 8501
    protocol  = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "mongo-sg" }
}







#EC2 Instances



resource "aws_instance" "web" {
  ami                         = var.instance_ami
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_web.id
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size = 32
    volume_type = "gp3"
  }

  tags = { Name = "laza-web-server" }
}

resource "aws_instance" "app" {
  ami                    = var.instance_ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private_app.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  root_block_device {
    volume_size = 64
    volume_type = "gp3"
  }

  tags = { Name = "laza-app-server" }
}

resource "aws_instance" "central" {
  ami                    = var.instance_ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private_central.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.central_sg.id]
  root_block_device {
    volume_size = 64
    volume_type = "gp3"
  }

  tags = { Name = "laza-central-server" }
}

resource "aws_instance" "mongo" {
  count         = 3
  ami           = var.instance_ami
  instance_type = var.instance_type
  subnet_id = element([
    aws_subnet.private_mongo_1.id,
    aws_subnet.private_mongo_2.id,
    aws_subnet.private_mongo_3.id
  ], count.index)
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.mongo_sg.id]
  root_block_device {
    volume_size = 128
    volume_type = "gp3"
  }

  tags = {
    Name = "laza-mongo-${count.index + 1}"
  }
}












## Elastic IP for Web Server
resource "aws_eip" "web_eip" {
  domain   = "vpc"
  instance = aws_instance.web.id

  tags = {
    Name = "laza-web-eip"
  }
}



