# Generates the SSH Key to access the instances securely
# and to add further security for configuration with Ansible
resource "tls_private_key" "kube_ssh" {
    algorithm = "RSA"
    rsa_bits = 4096
}

resource "local_file" "keyfile" {
    content = tls_private_key.kube_ssh.private_key_pem
    filename = "ssh_key.pem"
    file_permission = "0400"
}