resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  tags = { Name = var.env == "dev" ? "VPC-Duna" : "VPC-${var.env}" }
}

# Tag a la route table principal (default) creada automaticamente por AWS
# para identificarla claramente en la consola.

######### Internet Gateway #########
resource "aws_internet_gateway" "igw" { vpc_id = aws_vpc.main.id }

######### SubNets #########
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.pub_subnets[count.index]
  availability_zone = ["us-east-1a", "us-east-1d"][count.index]
  map_public_ip_on_launch = true
  tags                    = { Name = "Public-${var.env}-${count.index}" }
}

resource "aws_subnet" "app" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.app_subnets[count.index]
  availability_zone = ["us-east-1a", "us-east-1d"][count.index]
  tags              = { Name = "Private-App-${var.env}-${count.index}" }
}

resource "aws_subnet" "data" {
  count             = length(var.data_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.data_subnets[count.index]
  availability_zone = ["us-east-1a", "us-east-1d"][count.index]
  tags              = { Name = "Private-Data-${var.env}-${count.index}" }
}

# Elastic IPs and NAT Gateways: single NAT for simplified setup
resource "aws_eip" "nat" {
  count  = 1
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  count         = 1
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id
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
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[0].id
  }
}

resource "aws_route_table_association" "pub" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.pub.id
}

# Asociar subredes App a tabla privada única
resource "aws_route_table_association" "priv_app" {
  count          = length(aws_subnet.app)
  subnet_id      = aws_subnet.app[count.index].id
  route_table_id = aws_route_table.priv.id
}

# Asociar subredes Data a tabla privada única
resource "aws_route_table_association" "priv_data" {
  count          = length(aws_subnet.data)
  subnet_id      = aws_subnet.data[count.index].id
  route_table_id = aws_route_table.priv.id
}

output "vpc_id" { value = aws_vpc.main.id }
output "public_subnets" { value = aws_subnet.public[*].id }
output "app_private_subnets" { value = aws_subnet.app[*].id }
output "data_private_subnets" { value = aws_subnet.data[*].id }