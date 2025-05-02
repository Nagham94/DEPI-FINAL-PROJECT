module "master" {
    source = "./modules/server_module"
    server_name = "master"
    script_path = "master.sh"
    is_file_copied = true
    subnet_cidr_block = "172.31.0.32/28"
    file_name = "k8s-manifest.yml"
    is_master = true
    is_worker = false
}


#module "worker" {
#    source = "./modules/server_module"
#    server_name = "worker"
#    script_path = "worker.sh"
#    is_file_copied = true
#    subnet_cidr_block = "172.31.0.48/28"
#    is_master = false
#    is_worker = true
#}