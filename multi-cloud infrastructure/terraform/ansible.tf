# Ansible host to integrate terraform with ansible
#Also uses the inventory file to retrieve the public IP of the instances
resource "local_file" "ansible_host" {
    depends_on = [
        aws_instance.kube_master
    ]
    count = var.numb_worker
    content     = "[Master_Node]\n${aws_instance.kube_master.public_ip}\n\n[Worker_Node]\n${join("\n", azurerm_linux_virtual_machine.kube_worker.*.public_ip_address)}"
    filename    = "inventory"

}

resource "null_resource" "null" {
    depends_on = [
        local_file.ansible_host
    ]
    
    provisioner "local-exec" {

        command = "ansible-inventory --graph"
    }
    #Initiates the playbook
    provisioner "local-exec" {

        command = "ansible-playbook playbook.yml"
    }
  
}
