variable "server_name" {
  
} 

variable "script_path" {
  
}



variable "is_file_copied" {
  default = false
  type = bool
}

variable "file_name" {
  type = string
  default = ""
  description = "Flag to indicate if a file should be copied to the server"

}

variable "subnet_cidr_block" {
  type        = string
  description = "CIDR block for the subnet"
}

variable "is_master" {
  type    = bool
  default = false
}


variable "is_worker" {
  type    = bool
  default = false
}