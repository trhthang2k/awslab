# Main VPC
resource "aws_vpc" "hello_world_vpc" {
  cidr_block           = "10.100.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Internet Gateway for public access
resource "aws_internet_gateway" "public" {
  vpc_id = aws_vpc.hello_world_vpc.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Route Table for Public Subnets
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.hello_world_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.public.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Public Subnets in AZs a, b, c
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.hello_world_vpc.id
  cidr_block              = "10.100.1.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.hello_world_vpc.id
  cidr_block              = "10.100.2.0/24"
  availability_zone       = "ap-northeast-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-2"
  }
}

resource "aws_subnet" "public_subnet_3" {
  vpc_id                  = aws_vpc.hello_world_vpc.id
  cidr_block              = "10.100.3.0/24"
  availability_zone       = "ap-northeast-2c"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-3"
  }
}

# Associate Route Table with Public Subnets
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_3" {
  subnet_id      = aws_subnet.public_subnet_3.id
  route_table_id = aws_route_table.public_rt.id
}

# Private Subnets in AZs a, b, c
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.hello_world_vpc.id
  cidr_block        = "10.100.11.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "${var.project_name}-private-1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.hello_world_vpc.id
  cidr_block        = "10.100.12.0/24"
  availability_zone = "ap-northeast-2b"

  tags = {
    Name = "${var.project_name}-private-2"
  }
}

resource "aws_subnet" "private_subnet_3" {
  vpc_id            = aws_vpc.hello_world_vpc.id
  cidr_block        = "10.100.13.0/24"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "${var.project_name}-private-3"
  }
}

# Route Table for Private Subnets (no internet access by default)
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.hello_world_vpc.id

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

# Associate Route Table with Private Subnets
resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_3" {
  subnet_id      = aws_subnet.private_subnet_3.id
  route_table_id = aws_route_table.private_rt.id
}


# NAT
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip"
  }
}


resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_1.id

  tags = {
    Name = "${var.project_name}-nat-gw"
  }
}

resource "aws_route" "private_internet_access" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw.id
}




# Associate Private Subnets with Public Route Table (tạm thời để có Internet)
# resource "aws_route_table_association" "private_1" {
#   subnet_id      = aws_subnet.private_subnet_1.id
#   route_table_id = aws_route_table.public_rt.id
# }

# resource "aws_route_table_association" "private_2" {
#   subnet_id      = aws_subnet.private_subnet_2.id
#   route_table_id = aws_route_table.public_rt.id
# }

# resource "aws_route_table_association" "private_3" {
#   subnet_id      = aws_subnet.private_subnet_3.id
#   route_table_id = aws_route_table.public_rt.id
# }
