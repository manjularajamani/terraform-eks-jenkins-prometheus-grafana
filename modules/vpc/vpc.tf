resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "public_subnet" {
  for_each                = var.subnets_data
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = each.value.ip
  availability_zone       = each.value.zone
  map_public_ip_on_launch = "true"

  tags = {
    Name                               = each.value.name,
    "kubernetes.io/cluster/eks-master" = "shared",
    "kubernetes.io/role/elb"           = "1"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = var.gateway_name
  }
}

resource "aws_route_table" "route" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = var.route_table_cidr_block
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = var.route_table_name
  }
}

resource "aws_route_table_association" "route-association" {
  count          = length(var.subnets_data)
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.route.id
}