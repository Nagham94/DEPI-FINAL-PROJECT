# Fetch the default VPC
data "aws_vpc" "default" {
  default = true
}


# Fetch the most recent Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}


resource "aws_subnet" "subnet_server" {
  vpc_id            = data.aws_vpc.default.id
  cidr_block        = var.subnet_cidr_block
  availability_zone = "us-east-1a"
  tags = {
  name = "subnet_server_${var.server_name}"
  }
}
# Security Group for Kubernetes Cluster (Master + Worker)
resource "aws_security_group" "k8s_cluster_sg" {
  name        = "${var.server_name}-k8s-cluster-sg"
  description = "Security group for Kubernetes cluster nodes"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "${var.server_name}-k8s-cluster-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.k8s_cluster_sg.id
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "allow_k8s_api" {
  count             = var.is_master ? 1 : 0
  security_group_id = aws_security_group.k8s_cluster_sg.id
  from_port         = 6443
  to_port           = 6443
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "allow_etcd" {
  count             = var.is_master ? 1 : 0
  security_group_id = aws_security_group.k8s_cluster_sg.id
  from_port         = 2379
  to_port           = 2380
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "allow_kubelet" {
  security_group_id = aws_security_group.k8s_cluster_sg.id
  from_port         = 10250
  to_port           = 10250
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "allow_scheduler" {
  count             = var.is_master ? 1 : 0
  security_group_id = aws_security_group.k8s_cluster_sg.id
  from_port         = 10259
  to_port           = 10259
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "allow_controller_manager" {
  count             = var.is_master ? 1 : 0
  security_group_id = aws_security_group.k8s_cluster_sg.id
  from_port         = 10257
  to_port           = 10257
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "allow_kube_proxy" {
  count             = var.is_worker ? 1 : 0
  security_group_id = aws_security_group.k8s_cluster_sg.id
  from_port         = 10256
  to_port           = 10256
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "allow_nodeport" {
  security_group_id = aws_security_group.k8s_cluster_sg.id
  from_port         = 30004
  to_port           = 30004
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "allow_all" {
  security_group_id = aws_security_group.k8s_cluster_sg.id
  from_port         = 0
  to_port           = 0
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}





# Instance resource
resource "aws_instance" "server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.medium"
  key_name               = aws_key_pair.server_key.key_name
  vpc_security_group_ids = [aws_security_group.k8s_cluster_sg.id]
  subnet_id             = aws_subnet.subnet_server.id  
  associate_public_ip_address = true
  tags = {
    Name = "${var.server_name}-server"
  }
}




# Key pair for SSH access
resource "aws_key_pair" "server_key" {
  key_name   = "${var.server_name}-key"
  public_key = file("~/.ssh/id_rsa.pub")
}




resource "null_resource" "copy_file" {
  count = "${var.is_file_copied ? 1 : 0}"

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
    host        = aws_instance.server.public_ip
  }

  provisioner "file" {
    source = "${var.file_name}"
    destination = "/home/ubuntu/${var.file_name}"  
  }  

  depends_on = [ aws_instance.server ]
}




resource "null_resource" "remote" {

    connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
    host        = aws_instance.server.public_ip
  }

  provisioner "remote-exec" {
    script = "scripts/${var.script_path}"  
  }  

  depends_on = [ null_resource.copy_file ]
}


/*
resource "null_resource" "apply_manifest" {
  count = var.is_master ? 1 : 0

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
    host        = aws_instance.server.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "kubectl apply -f /home/ubuntu/k8s-manifest.yaml"  # Apply the Kubernetes manifest file
    ]
  }

  depends_on = [null_resource.copy_file]  # Ensure the file is copied before applying
}
*/