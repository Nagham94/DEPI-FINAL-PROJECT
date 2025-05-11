terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.96.0"
    }
  }
  backend "s3" {
    bucket = "my-depi-bucket-mostafa"
    key = "my-depi-state-file"
    region = "us-east-1"
    
  }
}

provider "aws" {
  region = "us-east-2"
  
}


module "master" {
    source = "./modules/server_module"
    server_name = "master"
    script_path = "master.sh"
    is_file_copied = true
    file_name_1 = "k8s-manifest.yml"
    file_name_2 = "node-exporter-daemonset.yml"
    file_name_3 = "prometheus-deployment.yml"
    file_name_4 = "prometheus-clusterrole.yml"
    file_name_5 = "prometheus-clusterrolebinding.yml"
    file_name_6 = "solar-app-secret.yml"
    is_master = true
    is_worker = false
    is_prom = false
    instance_type = "t2.medium"
}


module "worker" {
    source = "./modules/server_module"
    server_name = "worker"
    script_path = "worker.sh"
    is_file_copied = false
    is_master = false
    is_worker = true
    is_prom = false
    instance_type = "t2.medium"
    depends_on = [ module.master ]
}


module "prometheus_server" {
    source = "./modules/server_module"
    server_name = "prometheus"
    script_path = "prometheus.sh"
    is_file_copied = false
    instance_type = "t2.medium"  
    is_master = false
    is_worker = false
    is_prom = true
    depends_on = [ module.worker ]
}



resource "null_resource" "apply_k8s_manifests" {

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
    host        = module.master.server_ip  
  }

  provisioner "remote-exec" {
    script = "${path.module}/scripts/kubectl.sh"
  }

  depends_on = [
    module.master,
    module.worker,
    module.prometheus_server
  ]
}