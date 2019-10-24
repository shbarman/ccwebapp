resource "aws_security_group" "default" {
  name        = "rds_security_group"
  description = "To add the security group"
  vpc_id      = var.vpcId

  
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["${var.cidr_blocks}"]
    security_groups = "${var.security_group_id}"  
    
  }

   tags = {
    Name = "database"
  }
}