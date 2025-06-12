# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(local.common_tags, { Name = "${var.project_name}-vpc-${var.environment}" })
}

# Subnets Públicas
resource "aws_subnet" "public" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index % length(var.availability_zones)] # Distribui pelas AZs
  map_public_ip_on_launch = true
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-public-subnet-${count.index + 1}-${var.environment}"
  })
}

# Subnets Privadas
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index % length(var.availability_zones)]
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-private-subnet-${count.index + 1}-${var.environment}"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags   = merge(local.common_tags, { Name = "${var.project_name}-igw-${var.environment}" })
}

# Rota para Internet Gateway nas subnets públicas
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = merge(local.common_tags, { Name = "${var.project_name}-public-rt-${var.environment}" })
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Elastic IP para NAT Gateway (um por AZ para alta disponibilidade, se necessário, ou um compartilhado)
# Para simplicidade, vamos criar um EIP para um NAT Gateway.
resource "aws_eip" "nat" {
  tags   = merge(local.common_tags, { Name = "${var.project_name}-nat-eip-${var.environment}" })
  depends_on = [aws_internet_gateway.gw] # Garante que o IGW exista
}

# NAT Gateway (colocado em uma subnet pública)
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id # Coloca o NAT Gateway na primeira subnet pública
  tags          = merge(local.common_tags, { Name = "${var.project_name}-nat-gw-${var.environment}" })
  depends_on    = [aws_internet_gateway.gw]
}

# Rota para NAT Gateway nas subnets privadas
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = merge(local.common_tags, { Name = "${var.project_name}-private-rt-${var.environment}" })
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Security Group para o ALB (permite tráfego HTTP/HTTPS de entrada)
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg-${var.environment}"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Adicione HTTPS (443) se necessário

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Permite todo o tráfego de saída
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = local.common_tags
}

# Security Group para os serviços ECS Fargate (permite tráfego do ALB)
resource "aws_security_group" "ecs_tasks_sg" {
  name        = "${var.project_name}-ecs-tasks-sg-${var.environment}"
  description = "Security group for ECS tasks"
  vpc_id      = aws_vpc.main.id

  # Permite tráfego de entrada do ALB.
  # O tráfego para os containers virá do ALB, geralmente em portas altas.
  # O mapeamento de porta do ALB para o container (8080) será configurado no Target Group.
  ingress {
    from_port       = 8080 # Todos os serviços escutam na porta 8080 dentro do container
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
    description     = "Allow ALB to ECS tasks on container port 8080"
  }
  # Adicione mais blocos ingress aqui se você adicionar novos serviços com portas diferentes.

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = local.common_tags
}