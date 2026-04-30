resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = "mindmeld-redis-subnet"
  subnet_ids = module.vpc.private_subnets
}

# The Security Group acting as the firewall for our database
resource "aws_security_group" "redis_sg" {
  name        = "mindmeld-redis-sg"
  description = "Allow Redis traffic ONLY from EKS nodes"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Allow traffic from EKS worker nodes"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    # Least privilege: Only EKS nodes can access this port
    security_groups = [module.eks.node_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# The Redis Cluster
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "mindmeld-redis-cluster"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  engine_version       = "7.0"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.redis_subnet_group.name
  security_group_ids   = [aws_security_group.redis_sg.id]
}
