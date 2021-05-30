#################################################################
#Creating_VPC
#################################################################

resource "aws_vpc" "wordpress" {
    
  cidr_block       = "172.17.0.0/16"
  instance_tenancy = "default"
  enable_dns_support =  true
  enable_dns_hostnames = true
    
  tags = {
    Name = "wordpress"
  }
}



###############################################################
#Creating_Internet_gateway
###############################################################

resource "aws_internet_gateway" "wordpress" {
    
  vpc_id = aws_vpc.wordpress.id

  tags = {
    Name = "wordpress"
  }
}


#########################################################
#Creating_public-1_Subnet
##########################################################

resource "aws_subnet" "public1" {
    
  vpc_id     = aws_vpc.wordpress.id
  cidr_block = "172.17.0.0/18"
  availability_zone = "us-east-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "wordpress-public1"
  }
}

###############################################################################
# Crating public-2 Subnet
###############################################################################

resource "aws_subnet" "public2" {
    
  vpc_id     = aws_vpc.wordpress.id
  cidr_block = "172.17.64.0/18"
  availability_zone = "us-east-2b"
  map_public_ip_on_launch = true
  tags = {
    Name = "wordpress-public2"
  }
}


###############################################################################
# Crating private-1 Subnet
###############################################################################

resource "aws_subnet" "private1" {
    
  vpc_id     = aws_vpc.wordpress.id
  cidr_block = "172.17.128.0/18"
  availability_zone = "us-east-2c"
  map_public_ip_on_launch = false
  tags = {
    Name = "wordpress-private1"
  }
}

###############################################################################
# Crating elastic ip
###############################################################################

resource "aws_eip" "wordpress" {  
  vpc      = true
  tags = {
    Name = "wordpress"
  }
}


###############################################################################
# Crating nat gateway
###############################################################################

resource "aws_nat_gateway" "wordpress" {
  allocation_id = aws_eip.wordpress.id
  subnet_id     = aws_subnet.public2.id

  tags = {
    Name = "wordpress"
  }
}


###############################################################################
# Crating route table public
###############################################################################


resource "aws_route_table" "public" {
    
  vpc_id = aws_vpc.wordpress.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.wordpress.id
  }

  tags = {
    Name = "wordpress-public"
  }
}



###############################################################################
# Crating route table public
###############################################################################


resource "aws_route_table" "private" {
    
  vpc_id = aws_vpc.wordpress.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.wordpress.id
  }

  tags = {
    Name = "wordpress-private"
  }
}

###############################################################################
# public1 subenet to public route table association
###############################################################################


resource "aws_route_table_association" "public1" {
    
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
}


###############################################################################
# public2-subenet to public route table association
###############################################################################


resource "aws_route_table_association" "public2" {
    
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}


###############################################################################
# private1-subenet to private route table association
###############################################################################


resource "aws_route_table_association" "private1" {
    
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.private.id
}

###############################################################################
# Bastion
###############################################################################

resource "aws_security_group" "bastion" {
    
  name        = "wordpress-bastion"
  description = "allows 22 only"
  vpc_id      = aws_vpc.wordpress.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
    
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "wordpress-bastion"
  }
       
}



###############################################################################
# webserver security group
###############################################################################

resource "aws_security_group" "webserver" {
    
  name        = "wordpress-webserver"
  description = "allows 80,22 only"
  vpc_id      = aws_vpc.wordpress.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [ aws_security_group.bastion.id ]
  }
 
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
    
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "wordpress-webserver"
  }
       
}


###############################################################################
# database security group
###############################################################################

resource "aws_security_group" "database" {
    
  name        = "wordpress-database"
  description = "allows 3306,22 only"
  vpc_id      = aws_vpc.wordpress.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [ aws_security_group.bastion.id ]
  }
 
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [ aws_security_group.webserver.id ]
  }
 
    
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "wordpress-database"
  }
       
}




################################################################################
# Creating KeyPair
################################################################################

resource "aws_key_pair" "project" {
  key_name   = "project"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC81THGtSvfOlGfRDXwI6KXTzGuRqGiJkB1KljLm9FaP8PdlT9zP7gg5wbz/Gd5bY+YmoZ1BqzxwfDWcXjjnoR8MJdi39h0SbzRzyT4hQqTrAr/Hb4F9GOV5mpEu/yOeMIFxQ7bCK1e2v/a9ZL3EmZgKLbfCAU4nGVtLcLuGSw/SztiYNZJ6xFP6NS3QSGzQHdbR4JxrcYU+dXZcTptyySWbRj0XpIe90e0Qo3TIlnwqXmfPquotgWBnmhd1gMafYKQAyeX2C+yrIjbJYXuaYESPnaImw5o5QQ9JbKQD959F9gb8byeoDPWdsdQWCcYA0PxgO7zD61RyDOVKYokgDSP fuji@vps.server.com"
  tags = {
    Name = "project"
  }

}


###############################################################################
# Ec2 - bastion
###############################################################################

resource "aws_instance"   "bastion" {
     
  ami           = "ami-03657b56516ab7912"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public2.id
  vpc_security_group_ids = [ aws_security_group.bastion.id ]
  key_name = aws_key_pair.project.key_name
  tags = {
    Name = "bastion"
  }
      
}


###############################################################################
# Ec2 - webserver
###############################################################################

resource "aws_instance"   "webserver" {
     
  ami           = "ami-03657b56516ab7912"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public1.id
  vpc_security_group_ids = [ aws_security_group.webserver.id ]
  key_name = aws_key_pair.project.key_name
  user_data = file("apache-install.sh")
  tags = {
    Name = "webserver"
  }
      
}


###############################################################################
# Ec2 - database
###############################################################################

resource "aws_instance"   "database" {
     
  ami           = "ami-03657b56516ab7912"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.private1.id
  vpc_security_group_ids = [ aws_security_group.database.id ]
  key_name = aws_key_pair.project.key_name
  user_data = file("mariadb-install.sh")
  tags = {
    Name = "database"
  }
      
}
