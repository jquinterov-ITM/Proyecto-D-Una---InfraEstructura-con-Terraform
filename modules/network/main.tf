######### VPC #########
locals {
  azs = ["us-east-1a", "us-east-1d"]
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  #instance_tenancy     = "default"
  enable_dns_hostnames = true
  tags = {
    Name = var.env == "dev" ? "VPC-Duna" : "VPC-${var.env}"
  }
}

# Tag a la route table principal (default) creada automaticamente por AWS
# para identificarla claramente en la consola.
resource "aws_ec2_tag" "main_route_table_name" {
  resource_id = aws_vpc.main.main_route_table_id
  key         = "Name"
  value       = "RT-Main-${var.env}"
}

######### Internet Gateway #########
resource "aws_internet_gateway" "igw" { vpc_id = aws_vpc.main.id }

######### SubNets #########
resource "aws_subnet" "public" {
  count                   = length(var.pub_subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.pub_subnets[count.index]
  availability_zone       = local.azs[count.index % length(local.azs)]
  map_public_ip_on_launch = true
  tags                    = { Name = "Public-${var.env}-${count.index}" }
}

resource "aws_subnet" "app" {
  count             = length(var.app_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.app_subnets[count.index]
  availability_zone = local.azs[count.index % length(local.azs)]
  tags              = { Name = "Private-App-${var.env}-${count.index}" }
}

resource "aws_subnet" "data" {
  count             = length(var.data_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.data_subnets[count.index]
  availability_zone = local.azs[count.index % length(local.azs)]
  tags              = { Name = "Private-Data-${var.env}-${count.index}" }
}

# Elastic IPs and NAT Gateways: one NAT per public subnet (HA per AZ)
resource "aws_eip" "nat" {
  count  = length(aws_subnet.public)
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  count         = length(aws_subnet.public)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
}

resource "aws_network_acl" "main" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = concat(aws_subnet.public[*].id, aws_subnet.app[*].id, aws_subnet.data[*].id)

  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
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
  count  = length(aws_subnet.public)
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }
}

resource "aws_route_table_association" "pub" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.pub.id
}

# Asociar subredes App a tablas privadas (mapear por AZ index)
resource "aws_route_table_association" "priv_app" {
  count          = length(aws_subnet.app)
  subnet_id      = aws_subnet.app[count.index].id
  route_table_id = aws_route_table.priv[count.index % length(aws_subnet.public)].id
}

# Asociar subredes Data a tablas privadas (mapear por AZ index)
resource "aws_route_table_association" "priv_data" {
  count          = length(aws_subnet.data)
  subnet_id      = aws_subnet.data[count.index].id
  route_table_id = aws_route_table.priv[count.index % length(aws_subnet.public)].id
}

output "vpc_id" { value = aws_vpc.main.id }
output "main_route_table_id" { value = aws_vpc.main.main_route_table_id }
output "public_subnets" { value = aws_subnet.public[*].id }
output "app_private_subnets" { value = aws_subnet.app[*].id }
output "data_private_subnets" { value = aws_subnet.data[*].id }
output "private_subnets" { value = concat(aws_subnet.app[*].id, aws_subnet.data[*].id) }