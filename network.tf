#VPC
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
}

#subnet
resource "aws_subnet" "pub_1" {
  vpc_id            = aws_vpc.vpc.id
  availability_zone = "ap-northeast-1a"
  cidr_block        = "10.0.1.0/24"
}

resource "aws_subnet" "pub_2" {
  vpc_id            = aws_vpc.vpc.id
  availability_zone = "ap-northeast-1c"
  cidr_block        = "10.0.2.0/24"
}

#internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}


#aws route table
resource "aws_route_table" "pub_rt" {
  vpc_id = aws_vpc.vpc.id
}

#internet gatewayへのルート追加
resource "aws_route" "to_igw" {
  route_table_id         = aws_route_table.pub_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "pub_rt1" {
  subnet_id      = aws_subnet.pub_1.id
  route_table_id = aws_route_table.pub_rt.id
}

resource "aws_route_table_association" "pub_rt2" {
  subnet_id      = aws_subnet.pub_2.id
  route_table_id = aws_route_table.pub_rt.id
}
