resource "aws_subnet" "public_subnets" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                                = "${var.project_name}-public-subnet-${count.index + 1}"
    "kubernetes.io/cluster/sprints-eks" = "shared" # Best practice is to use 'shared'
    "kubernetes.io/role/elb"            = "1"
  }
}

resource "aws_subnet" "private_subnets" {
  count                   = length(var.private_subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnets[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name                                = "${var.project_name}-private-subnet-${count.index + 1}"
    "kubernetes.io/cluster/sprints-eks" = "shared" # Best practice is to use 'shared'
    "kubernetes.io/role/internal-elb"   = "1"
  }
}
