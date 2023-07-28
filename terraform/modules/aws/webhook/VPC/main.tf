resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  tags = {
    Name        = "${var.project}-${var.group}-vpc-${var.env}"
    Environment = var.env
    Group       = var.group
  }
}

resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(concat(var.public_subnets, [""]), count.index)
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = var.map_public_ip_on_launch
  depends_on              = [aws_vpc.main]
  tags = {
    Name        = "${var.project}-${element(var.azs, count.index)}-public-subnet-${var.env}"
    Environment = var.env
    Group       = var.group
  }
}

resource "aws_subnet" "private" {
  count = length(var.private_subnets)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = element(var.azs, count.index)
  depends_on        = [aws_vpc.main]
  tags = {
    Name        = "${var.project}-${element(var.azs, count.index)}-private-subnet-${var.env}"
    Environment = var.env
    Group       = var.group
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name        = "${var.project}-igw-${var.env}"
    Environment = var.env
    Group       = var.group
  }
}

#resource "aws_eip" "nat" {
#  vpc = true
#  depends_on = [aws_internet_gateway.main]  
#  tags = {
#    Name        = "${var.project}-eip-${var.env}"
#    Environment = var.env
#    Group     = var.group    
#  }
#}
#
#resource "aws_nat_gateway" "main" {
#  allocation_id = aws_eip.nat.id
#  subnet_id = element(aws_subnet.public.*.id, 0)
#  depends_on = [aws_internet_gateway.main]
#  tags = {
#    Name        = "${var.project}-nat-${var.env}"
#    Environment = var.env
#    Group     = var.group    
#  }
#}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name        = "${var.project}-private-route-table-${var.env}"
    Environment = var.env
    Group       = var.group
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name        = "${var.project}-public-route-table-${var.env}"
    Environment = var.env
    Group       = var.group
  }
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
  timeouts {
    create = "5m"
  }
}

#resource "aws_route" "private_nat_gateway" {
#  route_table_id         = aws_route_table.private.id
#  destination_cidr_block = "0.0.0.0/0"
#  nat_gateway_id         = aws_nat_gateway.main.id
#  timeouts {
#    create = "5m"
#  }
#}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets)
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets)
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = aws_route_table.private.id
}
