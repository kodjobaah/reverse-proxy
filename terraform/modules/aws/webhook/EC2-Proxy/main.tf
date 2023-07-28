########################
### Instance configs ###
########################

resource "aws_instance" "instance" {
  key_name                    = var.bastion_key_pair_name
  associate_public_ip_address = true
  instance_type               = var.instance_type
  ami                         = var.ec2_ami_id
  vpc_security_group_ids      = [aws_security_group.aws_instance_layer_security_group.id]
  subnet_id                   = var.subnet-1
  monitoring                  = true

  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.instance_volume_size_gb
    delete_on_termination = true
  }

  tags = {
    Name = "${var.project}-${var.group}-${var.env}-bastion"
    env  = var.env
  }
}

###############################
### Instance security layer ###
###############################

resource "aws_security_group" "aws_instance_layer_security_group" {
  name        = "${var.project}-${var.group}-${var.env}-bastion"
  description = "${var.project}-${var.group}-${var.env}-bastion"
  vpc_id      = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_eip" "proxy" {
  instance = aws_instance.instance.id
  vpc      = true
}