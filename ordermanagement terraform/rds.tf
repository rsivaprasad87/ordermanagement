# ----------------------------
# RDS Instance (Free Tier)
# ----------------------------
resource "aws_db_instance" "mysql" {
  allocated_storage      = 20
  max_allocated_storage  = 100
  engine                 = "mysql"
  engine_version         = "8.0.42"
  instance_class         = "db.t3.micro" # ✅ Free tier
  identifier             = var.db_instance_identifier
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  parameter_group_name   = "default.mysql8.0"
  multi_az               = false # Crucial for free tier - do not enable Multi-AZ
  storage_type           = "gp2" # General Purpose SSD
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.rds_subnets.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible    = true # ❗ Only for learning. For prod, use private subnets.

  tags = {
    Name = "${var.project_name}-rds"
  }
}