# Create VPC
resource "aws_vpc" "main_vpc" {
    cidr_block = "10.40.2.0/24"
    instance_tenancy = "default"
    enable_dns_hostnames = true
    enable_dns_support = true
    tags = {
        Name = "main-vpc"
        owner = "me"
    }
}

# Create Subnets
resource "aws_subnet" "main_public_subnet" {
    vpc_id = aws_vpc.main_vpc.id
    availability_zone = "eu-central-1a"
    cidr_block = "10.40.2.0/25"
    tags = {
        Name = "public-subnet-eu-central-1a"
        owner = "me"
    }
}

resource "aws_subnet" "main_private_subnet" {
    vpc_id = aws_vpc.main_vpc.id
    availability_zone = "eu-central-1a"
    cidr_block = "10.40.2.128/25"
    tags = {
        Name = "private-subnet-eu-central-1a"
        owner = "me"
    }
}

# Create Route Tables and the corresponding associations
resource "aws_route_table" "main_public_rt" {
    vpc_id = aws_vpc.main_vpc.id
    tags = {
        Name = "public-rt"
        owner = "me"
    }
}

resource "aws_route_table" "main_private_rt" {
    vpc_id = aws_vpc.main_vpc.id
    tags = {
        Name = "private-rt"
        owner = "me"
    }
}

resource "aws_route_table_association" "public_subnet_rt_association" {
    subnet_id = aws_subnet.main_public_subnet.id
    route_table_id = aws_route_table.main_public_rt.id
}

resource "aws_route_table_association" "private_subnet_rt_association" {
    subnet_id = aws_subnet.main_private_subnet.id
    route_table_id = aws_route_table.main_private_rt.id
}

# Security Group for allowing Inbound TLS Inside the VPC
resource "aws_security_group" "allow_tls_inside_vpc" {
    name        = "allow_tls"
    description = "Allow TLS inbound traffic"
    vpc_id      = aws_vpc.main_vpc.id

    ingress {
        description      = "TLS from VPC"
        from_port        = 443
        to_port          = 443
        protocol         = "tcp"
        cidr_blocks      = [aws_vpc.main_vpc.cidr_block]
    }

    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

    tags = {
        Name = "allow_tls"
        owner = "me"
    }
}

# VPC Interface Endpoints
resource "aws_vpc_endpoint" "ssm_interface_endpoint" {
    vpc_id            = aws_vpc.main_vpc.id
    service_name      = "com.amazonaws.eu-central-1.ssm"
    vpc_endpoint_type = "Interface"
    private_dns_enabled = true

    subnet_ids = [ 
        aws_subnet.main_private_subnet.id
    ]

    security_group_ids = [
        aws_security_group.allow_tls_inside_vpc.id
    ]

    tags = {
        owner = "me"
    }
}

resource "aws_vpc_endpoint" "ec2messages_interface_endpoint" {
    vpc_id            = aws_vpc.main_vpc.id
    service_name      = "com.amazonaws.eu-central-1.ec2messages"
    vpc_endpoint_type = "Interface"
    private_dns_enabled = true

    subnet_ids = [ 
        aws_subnet.main_private_subnet.id
    ]

    security_group_ids = [ 
        aws_security_group.allow_tls_inside_vpc.id 
    ]
    
    tags = {
        owner = "me"
    }
}

resource "aws_vpc_endpoint" "ec2_interface_endpoint" {
    vpc_id            = aws_vpc.main_vpc.id
    service_name      = "com.amazonaws.eu-central-1.ec2"
    vpc_endpoint_type = "Interface"
    private_dns_enabled = true
    
    subnet_ids = [ 
        aws_subnet.main_private_subnet.id
    ]

    security_group_ids = [
        aws_security_group.allow_tls_inside_vpc.id
    ]

    tags = {
        owner = "me"
    }
}

resource "aws_vpc_endpoint" "ssmmessages_interface_endpoint" {
    vpc_id            = aws_vpc.main_vpc.id
    service_name      = "com.amazonaws.eu-central-1.ssmmessages"
    vpc_endpoint_type = "Interface"
    private_dns_enabled = true

    subnet_ids = [ 
        aws_subnet.main_private_subnet.id
    ]
    
    security_group_ids = [
        aws_security_group.allow_tls_inside_vpc.id 
    ]
    
    tags = {
        owner = "me"
    }
}

# VPC Gateway Endpoint for S3

resource "aws_vpc_endpoint" "s3_gateway_endpoint" {
    vpc_id       = aws_vpc.main_vpc.id
    service_name = "com.amazonaws.eu-central-1.s3"
    vpc_endpoint_type = "Gateway"

    tags = {
        owner = "me"
    }
}