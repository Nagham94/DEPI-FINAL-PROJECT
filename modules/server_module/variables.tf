variable "server_name" {
  
} 

variable "script_path" {
  
}

variable "is_file_copied" {
  default = false
  type = bool
}

variable "file_name_1" {
  type = string
  default = ""
  description = "Flag to indicate if a file should be copied to the server"

}
variable "file_name_2" {
  type = string
  default = ""
  description = "Flag to indicate if a file should be copied to the server"

}
variable "file_name_3" {
  type = string
  default = ""
  description = "Flag to indicate if a file should be copied to the server"

}

variable "file_name_4" {
  type = string
  default = ""
  description = "Flag to indicate if a file should be copied to the server"

}

variable "file_name_5" {
  type = string
  default = ""
  description = "Flag to indicate if a file should be copied to the server"

}

variable "file_name_6" {
  type = string
  default = ""
  description = "Flag to indicate if a file should be copied to the server"

}






variable "is_master" {
  type    = bool
  default = false
}


variable "is_worker" {
  type    = bool
  default = false
}

variable "instance_type" {
  
}


variable "is_prom" {
  type    = bool
  default = false
}


variable "is_last_resource" {
  type    = bool
  default = false
}






variable "local_kubeadm_path" {
  default = "/home/agent/Desktop/depi-final/aws-terra/DEPI-FINAL-PROJECT/kubeadm_join.txt"
}