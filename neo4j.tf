#
# This file contains terraform infrastructure code to deploy a Neo4J database
# on an Ubuntu 20.04 EC2 instance for the pharmaDB backend
#
# @author Anthony Mancini
# @version 1.0.0
# @license GNU GPLv3 or later
#

# Setting AWS as the provider with North Virginia as the region
provider "aws" {
  region = "us-east-1"
}

# Specifying the keypair that will be used for the Neo4J instance
resource "aws_key_pair" "neo4j_ubuntu_20_db_key_pair" {
  key_name   = "neo4j_key"
  public_key = file("neo4j_key.pub")
}

# Creating a new security group for the Neo4J instance and allowing HTTP, 
# HTTPS, and SSH inbound traffic
resource "aws_security_group" "neo4j_ubuntu_20_db_security_group" {
  name        = "neo4j_ubuntu_20_db_security_group"
  description = "Allow inbound HTTP, HTTPS and SSH traffic"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
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
    Name = "neo4j_security_group"
  }
}

#
# EC2 Instance for the Neo4J Database
#
resource "aws_instance" "neo4j_ubuntu_20_db_instance" {
  # AMI for Ubuntu 20.04 Server instance
  ami           = "ami-042e8287309f5df03"

  # t2.small instance has 2 GB of RAM, and can be adjusted upwards as 
  # additional RAM is needed to run Neo4J
  instance_type = "t2.small"

  # Setting this variable to true in order to connect to our instance with SSH
  associate_public_ip_address = true

  # Setting the SSH keypair that will be associated with the instance
  key_name         = "neo4j_key"

  # Associating this instance with the newly created neo4j security group
  vpc_security_group_ids = [aws_security_group.neo4j_ubuntu_20_db_security_group.id]

  # A tag identifying the Neo4J instance
  tags = {
    Name = "neo4j_ubuntu_20_db_instance"
  }

  # Adding an additional 30 GB of storage to the EC2 instance in order to have 
  # enough space for the Neo4J database and the associated data
  root_block_device {
    volume_type           = "standard"
    volume_size           = 30
    delete_on_termination = true
  }

  # Setting up a file provisioner to ssh the post install script to the EC2
  # instance after it has been created
  provisioner "file" {
    source      = "./neo4j_postinstall.sh"
    destination = "~/neo4j_postinstall.sh"
  }

  # Setting up the SSH connection that will be used with the file provisioner
  # to run the post install script
  connection {
    type        = "ssh"
    user        = "ubuntu"
    password    = ""
    private_key = file("neo4j_key")
    host        = self.public_ip
  }

  # Runs the post install script that will download Docker and pull the docker
  # container for Neo4J, and then run the Neo4J container. See the post install
  # bash script in this repository for more information.
  provisioner "remote-exec" {
    inline = [
      "chmod +x ~/neo4j_postinstall.sh",
      "sudo ~/neo4j_postinstall.sh",
    ]
  }
}
