

locals {
  name = "coreon-dev"
  tags = {
    Project     = "coreon"
    Environment = "dev"
    ManagedBy   = "terraform"
    }
}
//vpc

resource "aws_vpc" "this" {
    cidr_block = var.vpc_cidr
    enable_dns_support  = true
    enable_dns_hostnames = true

    tags = merge(local.tags, {
        Name = local.name
    })
}

//subnet

resource "aws_subnet" "public" {
    count = length(var.public_subnet_cidrs)
    vpc_id = aws_vpc.this.id
    availability_zone = var.azs[count.index]
    cidr_block = var.public_subnet_cidrs[count.index]
    map_public_ip_on_launch = true

    tags = merge(local.tags, {
        Name = "${local.name}-public-${count.index +1 }"
        Tier ="public"
    })
}


resource "aws_subnet" "private_app" {
  count             = length(var.azs)
  vpc_id            = aws_vpc.this.id
  availability_zone = var.azs[count.index]
  cidr_block        = var.private_app_subnet_cidrs[count.index]

  tags = merge(local.tags, {
    Name = "${local.name}-private-app-${count.index + 1}"
    Tier = "private-app"
  })
}


resource "aws_subnet" "private_db" {
  count             = length(var.azs)
  vpc_id            = aws_vpc.this.id
  availability_zone = var.azs[count.index]
  cidr_block        = var.private_db_subnet_cidrs[count.index]

  tags = merge(local.tags, {
    Name = "${local.name}-private-db-${count.index + 1}"
    Tier = "private-db"
  })
}


//Internet Gateway 

resource "aws_internet_gateway" "igw"{
    vpc_id=aws_vpc.this.id

    tags = merge(local.tags, {
        Name = "${local.name}-igw"
    })
}

//Route Tables

resource "aws_route_table" "public"{
    vpc_id = aws_vpc.this.id

    tags = merge(local.tags, {
        Name = "${local.name}-rt-public"
    })
}

resource "aws_route" "public_internet"{
    route_table_id = aws_route_table.public.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public" {
    count   = length(var.public_subnet_cidrs)
    subnet_id = aws_subnet.public[count.index].id
    route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private_app" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.tags, {
    Name = "${local.name}-rt-private-app"
  })
}

resource "aws_route_table" "private_db" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.tags, {
    Name = "${local.name}-rt-private-db"
  })
}

resource "aws_route_table_association" "private_app" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private_app.id
}

resource "aws_route_table_association" "private_db" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.private_db[count.index].id
  route_table_id = aws_route_table.private_db.id
}
