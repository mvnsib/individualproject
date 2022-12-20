#Variable used for aws region
variable "aws_region" {
  default     = "eu-west-2"
  description = "AWS region"
}
#Variable used for aws zone
variable aws_availability_zone {
  default = "eu-west-2a"
}
#Variable used for azure region
variable "az_region" {
  default     = "West US 3"
  description = "Azure Region"
}
#Variable used for EC2 master node name
variable "master_nodename"{
  default = "kubernetes-master"
} 
#Variable used for azure worker node name
variable "worker_nodename"{
  default = "kubernetes-worker"
}
#Variable used for number of Azure workers
variable "numb_worker" {
  type = number
  description = "Number of worker nodes"
}
