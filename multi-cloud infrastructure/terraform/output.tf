#End of cluster configuration it will print out the public IP of all nodes
output "Master_Node_IP" {
  value = ["${aws_instance.kube_master.*.public_ip}"]
}
output "Worker_Node_IP" {
  value = join(", ", azurerm_linux_virtual_machine.kube_worker.*.public_ip_address)
}