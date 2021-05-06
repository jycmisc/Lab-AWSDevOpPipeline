terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~>3.0"
        }
    }
}

# Configure the AWS provider

provider "aws" {
    region = "us-east-1"
}

# Create a VPC

resource "aws_vpc" "Lab-VPC"{
    cidr_block = var.cidr_block[0]
    enable_dns_hostnames = true

    tags = {
        Name = "Lab-VPC"
    }
}

# Create a Subnet (Public)

resource "aws_subnet" "Lab-Subnet1" {
    vpc_id = aws_vpc.Lab-VPC.id
    cidr_block = var.cidr_block[1]

    tags = {
        Name = "Lab-Subnet1"
    }
}

# Create Internet Gateway

resource "aws_internet_gateway" "Lab-IntGW" {
    vpc_id = aws_vpc.Lab-VPC.id

    tags = {
        Name = "Lab-InternetGW"
    }
}

# Create Security Group

resource "aws_security_group" "Lab-Sec-Group" {
    vpc_id = aws_vpc.Lab-VPC.id
    name = "Lab Security Group"
    description = "Allow inbound and outbound traffic to lab instances"

    dynamic ingress {
        iterator = port
        for_each = var.ports
            content {
                from_port = port.value
                to_port = port.value
                protocol = "tcp"
                cidr_blocks = ["0.0.0.0/0"]
            }
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "allow traffic"
    }
}

# Create route table and association

resource "aws_route_table" "Lab-RouteTable" {
    vpc_id = aws_vpc.Lab-VPC.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.Lab-IntGW.id
    }

    tags = {
        Name = "Lab-RouteTable"
    }
}

resource "aws_route_table_association" "Lab-RouteAssn" {
    subnet_id = aws_subnet.Lab-Subnet1.id
    route_table_id = aws_route_table.Lab-RouteTable.id
}

# Create a Jenkins AWS EC2 Instance

resource "aws_instance" "Jenkins" {
    ami           = var.ami
    instance_type = var.instance_type
    key_name = "awsiac"
    vpc_security_group_ids = [ aws_security_group.Lab-Sec-Group.id ]
    subnet_id = aws_subnet.Lab-Subnet1.id
    associate_public_ip_address = true
    user_data = file("./InstallJenkins.sh")

    tags = {
    Name = "Jenkins-Server"
    }
}

# Create Jenkins EC2 Instance EIP

resource "aws_eip" "Jenkins_EIP" {
    instance = aws_instance.Jenkins.id
    vpc = true

    tags = {
        Name = "Jenkins_EIP"
    }
}

# Create an Ansible Control Node  AWS EC2 Instance

resource "aws_instance" "AnsibleController" {
    ami           = var.ami
    instance_type = var.instance_type
    key_name = "awsiac"
    vpc_security_group_ids = [ aws_security_group.Lab-Sec-Group.id ]
    subnet_id = aws_subnet.Lab-Subnet1.id
    associate_public_ip_address = true
    user_data = file("./InstallAnsibleCN.sh")

    tags = {
    Name = "Ansible-ControlNode"
    }
}

# Create Ansible Control Node EC2 Instance EIP

resource "aws_eip" "AnsibleController_EIP" {
    instance = aws_instance.AnsibleController.id
    vpc = true

    tags = {
        Name = "Ansible-ControlNode_EIP"
    }
}

# Create an Ansible Managed Node Apache Server AWS EC2 Instance

resource "aws_instance" "AnsibleManagedNode1" {
    ami           = var.ami
    instance_type = var.instance_type
    key_name = "awsiac"
    vpc_security_group_ids = [ aws_security_group.Lab-Sec-Group.id ]
    subnet_id = aws_subnet.Lab-Subnet1.id
    associate_public_ip_address = true
    user_data = file("./AnsibleManagedNode.sh")

    tags = {
        Name = "AnsibleMN-ApacheTomcat"
    }
}

# Create Ansible Managed Node Apache Server AWS EC2 Instance EIP

resource "aws_eip" "AnsibleManagedNode1_EIP" {
    instance = aws_instance.AnsibleManagedNode1.id
    vpc = true

    tags = {
        Name = "AnsibleMN-ApacheTomcat_EIP"
    }
}

# Create an Ansible Managed Node Docker AWS EC2 Instance

resource "aws_instance" "AnsibleManagedNode2" {
    ami           = var.ami
    instance_type = var.instance_type
    key_name = "awsiac"
    vpc_security_group_ids = [ aws_security_group.Lab-Sec-Group.id ]
    subnet_id = aws_subnet.Lab-Subnet1.id
    associate_public_ip_address = true
    user_data = file("./Docker.sh")

    tags = {
        Name = "AnsibleMN-DockerHost"
    }
}

# Create Ansible Managed Node Docker AWS EC2 Instance EIP
resource "aws_eip" "DockerHost_EIP" {
    instance = aws_instance.AnsibleManagedNode2.id
    vpc = true

    tags = {
        Name = "AnsibleMN-DockerHost_EIP"
    }
}

# Create a Sonartype Nexus on AWS EC2 Instance

resource "aws_instance" "Nexus" {
    ami           = var.ami
    instance_type = var.instance_type_for_nexus
    key_name = "awsiac"
    vpc_security_group_ids = [ aws_security_group.Lab-Sec-Group.id ]
    subnet_id = aws_subnet.Lab-Subnet1.id
    associate_public_ip_address = true
    user_data = file("./InstallNexus.sh")

    tags = {
    Name = "Nexus-Server"
    }
}

# Create a Sonartype Nexus on AWS EC2 Instance EIP
resource "aws_eip" "Nexus_EIP" {
    instance = aws_instance.Nexus.id
    vpc = true

    tags = {
        Name = "Nexus_EIP"
    }
}