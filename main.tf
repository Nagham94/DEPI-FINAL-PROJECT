terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.96.0"
    }
  }
  backend "s3" {
    bucket = "my-depi-bucket-nagham"
    key = "my-depi-state-file"
    region = "us-east-2"
    
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


variable "is_master" {
  type    = bool
  default = false
}


resource "null_resource" "apply_k8s_manifests" {


  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("/home/agent/.ssh/id_rsa")
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


# kubeadm token create --print-join-command
#sudo ssh ubuntu@ "sudo cp /home/ubuntu/file_join /home/ubuntu"


#sudo ssh ubuntu@ "sudo chown ubuntu:ubuntu /home/ubuntu/file_join"
#scp ubuntu@:/home/ubuntu/file_join join



# scp ubuntu@54.165.58.83:/home/ubuntu/kubeadm_join.txt kubeadm_join.txt  from remote to local 


#scp kubeadm_join.txt ubuntu@52.203.18.162:/home/ubuntu/

#ssh ubuntu@52.203.18.162 "sudo bash /home/ubuntu/kubeadm_join.txt"
# kubectl get all -A  # Shows pods, services, deployments, etc. in all namespaces
