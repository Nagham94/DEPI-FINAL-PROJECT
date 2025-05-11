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

  owners = ["099720109477"] 
}


resource "aws_security_group" "k8s_cluster_sg" {
  name        = "${var.server_name}-k8s-cluster-sg"
  description = "Security group for Kubernetes cluster nodes"
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


resource "aws_vpc_security_group_ingress_rule" "allow_kubelet" {
  security_group_id = aws_security_group.k8s_cluster_sg.id
  from_port         = 10250
  to_port           = 10250
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
}


resource "aws_vpc_security_group_ingress_rule" "allow_nodeport_for_app_solar" {
  security_group_id = aws_security_group.k8s_cluster_sg.id
  from_port         = 30004
  to_port           = 30004
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
}
resource "aws_vpc_security_group_ingress_rule" "allow_nodeport_for_metrices" {
  security_group_id = aws_security_group.k8s_cluster_sg.id
  from_port         = 9100
  to_port           = 9100
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "allow_nodeport_for_prom" {
  security_group_id = aws_security_group.k8s_cluster_sg.id
  from_port         = 30090
  to_port           = 30090
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
  count             = (var.is_worker || var.is_prom) ? 1 : 0
  security_group_id = aws_security_group.k8s_cluster_sg.id
  from_port         = 10256
  to_port           = 10256
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
}



resource "aws_vpc_security_group_egress_rule" "allow_all" {
  security_group_id = aws_security_group.k8s_cluster_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}




resource "aws_instance" "server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "${var.instance_type}"
  key_name               = aws_key_pair.server_key.key_name
  vpc_security_group_ids = [aws_security_group.k8s_cluster_sg.id]
  associate_public_ip_address = true
  tags = {
    Name = "${var.server_name}-server"
  }
}


resource "aws_key_pair" "server_key" {
  key_name   = "${var.server_name}-key"
  public_key = file("~/.ssh/id_rsa.pub")
}


resource "null_resource" "copy_all_files" {
  count = var.is_file_copied ? 1 : 0

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
    host        = aws_instance.server.public_ip
  }

  provisioner "file" {
    source      = "deploy_all_files/${var.file_name_1}"
    destination = "/home/ubuntu/${var.file_name_1}"
  }

  provisioner "file" {
    source      = "deploy_all_files/${var.file_name_2}"
    destination = "/home/ubuntu/${var.file_name_2}"
  }

  provisioner "file" {
    source      = "deploy_all_files/${var.file_name_3}"
    destination = "/home/ubuntu/${var.file_name_3}"
  }

  provisioner "file" {
    source      = "deploy_all_files/${var.file_name_4}"
    destination = "/home/ubuntu/${var.file_name_4}"
  }

  provisioner "file" {
    source      = "deploy_all_files/${var.file_name_5}"
    destination = "/home/ubuntu/${var.file_name_5}"
  }
  provisioner "file" {
    source      = "deploy_all_files/${var.file_name_6}"
    destination = "/home/ubuntu/${var.file_name_6}"
  }
  depends_on = [aws_instance.server]
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

  depends_on = [ aws_instance.server ]
}



resource "null_resource" "copy-file-from-master" {
  count             = var.is_master ? 1 : 0

    connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
    host        = aws_instance.server.public_ip
  }

    provisioner "local-exec" {
    command = "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@${aws_instance.server.public_ip}:/home/ubuntu/kubeadm_join.txt ${var.local_kubeadm_path}"
  }
  depends_on = [ aws_instance.server ,null_resource.remote]
}




resource "null_resource" "copy-file-to-prometheus-and-execute" {
  count = var.is_prom ? 1 : 0

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
    host        = aws_instance.server.public_ip
  }

  provisioner "file" {
    source      = "${var.local_kubeadm_path}"
    destination = "/home/ubuntu/kubeadm_join.txt"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo $(cat /home/ubuntu/kubeadm_join.txt)"
    ]
  }


  depends_on = [ aws_instance.server ,null_resource.copy-file-from-master]
}



resource "null_resource" "copy-file-to-worker-and-execute" {
  count = var.is_worker ? 1 : 0

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
    host        = aws_instance.server.public_ip
  }

  provisioner "file" {
    source      = "${var.local_kubeadm_path}"
    destination = "/home/ubuntu/kubeadm_join.txt"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo $(cat /home/ubuntu/kubeadm_join.txt)"
    ]
  }
  depends_on = [ aws_instance.server, null_resource.copy-file-from-master]
}



