######### VPC #########
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  #instance_tenancy     = "default"
  enable_dns_hostnames = true
  tags = { Name = "VPC-${var.env}" }
}

######### Internet Gateway #########
resource "aws_internet_gateway" "igw" { vpc_id = aws_vpc.main.id }

######### SubNets #########
resource "aws_subnet" "public" {
  count = 2
  vpc_id = aws_vpc.main.id
  cidr_block = var.pub_subnets[count.index]
  availability_zone = ["us-east-1a", "us-east-1d"][count.index]
  map_public_ip_on_launch = true
  tags = { Name = "Public-${var.env}-${count.index}" }
}

resource "aws_subnet" "private" {
  count = 6
  vpc_id = aws_vpc.main.id
  cidr_block = var.priv_subnets[count.index]
  availability_zone = ["us-east-1a", "us-east-1d","us-east-1a", "us-east-1d","us-east-1a", "us-east-1d"][count.index]
  tags = { Name = "Private-${var.env}-${count.index}" }
}


# Elastic IP para NAT Gateway
resource "aws_eip" "nat" {  domain = "vpc" }

# NAT Gateway en la Subnet pública 1
resource "aws_nat_gateway" "nat" {
    allocation_id = aws_eip.nat.id
    subnet_id = aws_subnet.public[0].id
}

resource "aws_network_acl" "main" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)

  ingress {
    protocol = "-1"
    rule_no = 100
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 0
    to_port = 0
    }
  egress {
    protocol = "-1"
    rule_no = 100
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 0
    to_port = 0
    }
  tags = { Name = "NACL-${var.env}" }
}

######### Route Tables #########

# Tabla de rutas pública
resource "aws_route_table" "pub" {
    vpc_id = aws_vpc.main.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
}

# tabla de rutas privada
resource "aws_route_table" "priv" {
    vpc_id = aws_vpc.main.id
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat.id
    }
}

resource "aws_route_table_association" "pub" {
    count = 2
    subnet_id = aws_subnet.public[count.index].id
    route_table_id = aws_route_table.pub.id
}

resource "aws_route_table_association" "priv" {
    count = 2
    subnet_id = aws_subnet.private[count.index].id
    route_table_id = aws_route_table.priv.id
}

output "vpc_id" { value = aws_vpc.main.id }
output "public_subnets" { value = aws_subnet.public[*].id }
output "private_subnets" { value = aws_subnet.private[*].id }