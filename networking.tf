# Main VPC for the project
resource "aws_vpc" "hello_world_vpc" {
  cidr_block           = "10.100.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Internet Gateway – required to provide public internet access
resource "aws_internet_gateway" "public" {
  vpc_id = aws_vpc.hello_world_vpc.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Public Route Table – routes traffic to the Internet Gateway
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.hello_world_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.public.id  # Route all outbound traffic to the Internet
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Public Subnets in 3 Availability Zones (with auto-assigned public IPs)
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.hello_world_vpc.id
  cidr_block              = "10.100.1.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true  # Automatically assign public IP to instances

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

# Associate public route table with public subnets
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

# Private Subnets in 3 Availability Zones (no public IPs)
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

# Private Route Table – used by private subnets (no direct internet access)
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.hello_world_vpc.id

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

# Associate private route table with private subnets
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

# Elastic IP for NAT Gateway – allows private subnets to access the internet
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip"
  }
}

# NAT Gateway in public subnet – provides outbound internet access for private subnets
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_1.id  # NAT must be in a public subnet

  tags = {
    Name = "${var.project_name}-nat-gw"
  }
}

# Add default route in private route table through NAT Gateway
resource "aws_route" "private_internet_access" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw.id
}

# TEMPORARY: Associate private subnets to public route table for internet access
# (use only if NAT gateway is not set up yet)
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
