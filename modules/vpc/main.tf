# Create the VPC
resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true  // Set to true if you want to use DNS hostnames for instances in this VPC

  tags = merge(
    var.common_tags,
    {
      Name = var.vpc_name
    }
  )
}

# Create an Internet Gateway and attach it to the VPC
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.vpc_name}-igw"
    }
  )
}


# Create Public Subnets
resource "aws_subnet" "public" {
  # Create one subnet for each entry in public_subnets map
  for_each = var.public_subnets

  vpc_id = aws_vpc.this.id

  # CIDR block comes from map value
  cidr_block = each.value.cidr

  # Assign subnet to AZ based on its position in the map
  #var.azs[0] if we want to create all subnets in same AZ.we cannot use count.index here because we are using for_each, so we use index function to get the position of the subnet in the map and assign AZ accordingly
  availability_zone = each.value.az

  # Automatically assign public IPs to EC2 launched here
  map_public_ip_on_launch = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.vpc_name}-${each.key}"
    }
  )
}

# Create Private Subnets
resource "aws_subnet" "private" {
  # Create one subnet for each entry in private_subnets map
  for_each = var.private_subnets

  vpc_id = aws_vpc.this.id

  # CIDR block comes from map value
  cidr_block = each.value

  # Assign subnet to AZ based on its position in the map
  availability_zone = element(var.azs,index(keys(var.private_subnets), each.key))

  tags = merge(
    var.common_tags,
    {
      Name = "${var.vpc_name}-${each.key}"
    }
  )
}


# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  count = var.create_nat_gateway ? 1 : 0

  domain = "vpc"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.vpc_name}-nat-eip"
    }
  )
}

# NAT Gateway in first public subnet
resource "aws_nat_gateway" "this" {
  count = var.create_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[keys(aws_subnet.public)[0]].id  # we created subnet using keys so we need to use keys (for_each)

  tags = merge(
    var.common_tags,
    {
      Name = "${var.vpc_name}-nat-gateway"
    }
  )

  depends_on = [aws_internet_gateway.this]
}


# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  # Route all internet-bound traffic to the Internet Gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.vpc_name}-public-rt"
    }
  )
}

# Associate all Public Subnets with the Public Route Table
resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}



# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  # No internet route because NAT Gateway is not used
  # AWS automatically creates the local VPC route

  tags = merge(
    var.common_tags,
    {
      Name = "${var.vpc_name}-private-rt"
    }
  )
}

# Route Private Subnets to NAT Gateway
resource "aws_route" "private_nat" {
  count = var.create_nat_gateway ? 1 : 0

  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[0].id  # we are using count here that why we need to mention zero.
}


# Associate all Private Subnets with the Private Route Table
resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

