terraform {
    required_version = ">= 0.10.0"
}

provider "azurerm" {
  features{}

}
#Resource for Azure Resource group and calling it #kubernetes_resource_group
resource "azurerm_resource_group" "kubernetes_group"{
    name = "kubernetes_resource_group"
    #Location variable stored in variable.tf
    location = var.az_region
}
#Network security group allowing all inbound traffic
resource "azurerm_network_security_group" "kubernetes_security_group"{
    name = "kubernetes_network_security_group"
    location =  var.az_region
    #Assigning it to the resource group in Azure
    resource_group_name = azurerm_resource_group.kubernetes_group.name
    #Security rule allowing all inbound traffic with any TCP port range
    security_rule {
        name                       = "allowall"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}
#Virtual network for Azure's private network, allowing secure communication 
resource "azurerm_virtual_network" "kubernetes_network"{
    name = "kubernetes_vnet"
    location = var.az_region
    address_space = ["10.2.0.0/16"]
    resource_group_name = azurerm_resource_group.kubernetes_group.name
}

resource "azurerm_public_ip" "kubernetes_public_ip"{
    count = var.numb_worker
    location = var.az_region
    #as there are 2 VM, we require 2 IPs this specifies where the public IP should exist
    name = "kubernetes_public_ip${count.index}"
    resource_group_name = azurerm_resource_group.kubernetes_group.name
    allocation_method = "Dynamic"
}

#defining the subnet here and setting the range of IP
resource "azurerm_subnet" "kubernetes_subnet" {
    name = "kube_subnet"
    virtual_network_name = azurerm_virtual_network.kubernetes_network.name
    resource_group_name = azurerm_resource_group.kubernetes_group.name
    address_prefixes = ["10.2.0.0/24"]
}
#Important as this enables azure VM to communicate to the internet
resource "azurerm_network_interface" "kubernetes_interface"{
    count = var.numb_worker
    location = var.az_region
    name = "kubernetes_NI_${count.index}"
    #assigning to its resource group
    resource_group_name = azurerm_resource_group.kubernetes_group.name
    ip_configuration {
      name = "Worker_NIConfig_${count.index}"
      subnet_id = azurerm_subnet.kubernetes_subnet.id
      private_ip_address_allocation = "Dynamic"
      #setting a public ip address for each VM
      public_ip_address_id = "${element(azurerm_public_ip.kubernetes_public_ip.*.id, count.index)}"
    }
}
#ACL
resource "azurerm_network_interface_security_group_association" "kubernetes_NI_security_group"{
    count = var.numb_worker
    network_interface_id = "${element(azurerm_network_interface.kubernetes_interface.*.id, count.index)}"
    network_security_group_id =  azurerm_network_security_group.kubernetes_security_group.id
}
#Defining the virtual machine instance 
resource "azurerm_linux_virtual_machine" "kube_worker"{
    count = var.numb_worker
    location = var.az_region
    name = "kubeVM${count.index}"
    #assigning to its resource group
    resource_group_name = azurerm_resource_group.kubernetes_group.name
    network_interface_ids = ["${element(azurerm_network_interface.kubernetes_interface.*.id, count.index)}"]
    #instance type is standard ds2 v2 with 2 vCPU and 7 GiB of Memory
    size = "Standard_DS2_v2"
    os_disk {
        name = "myOsDisk${count.index}"
        caching = "ReadWrite"
        disk_size_gb = 200
        storage_account_type = "Standard_LRS"
        
    }
    #External Machine image from Azure marketplace
    source_image_reference {
      publisher = "redhat"
      offer = "rhel"
      sku = "8.2"
      version = "latest"
    }
    #defining the computer name in Azure portal
    computer_name  = "WorkerNode${count.index}"
    #Username when ssh into the VM
    admin_username = "vm-user"
    admin_ssh_key {
      username = "vm-user"
      public_key = tls_private_key.kube_ssh.public_key_openssh
    }
}