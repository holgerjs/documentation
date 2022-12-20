resource "aws_network_interface" "ubuntu-nic" {
    subnet_id = aws_subnet.main_private_subnet.id

    security_groups = [ 
        aws_security_group.allow_tls_inside_vpc.id
    ]

    tags = {
      Name = "ubuntu-primary-nic"
      owner = "me"
    }
}

resource "aws_instance" "ubuntu_linux" {
    ami = "ami-09042b2f6d07d164a"
    instance_type = "t2.micro"
    iam_instance_profile = "AmazonSSMRoleForInstancesQuickSetup"

    network_interface {
      network_interface_id = aws_network_interface.ubuntu-nic.id
      device_index = 0

    }

    tags = {
        Name = "test-ubn-01"
        OS = "Ubuntu16.04LTS"
        owner = "me"
    }
}
