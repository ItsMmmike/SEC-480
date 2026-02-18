# Script used to install ansible onto a ubuntu based system
## To Use: Download Script from this repo, then run with "sudo bash ./install.ansible.bash"

# Install Ansible Dependencies
sudo apt install sshpass python3-paramiko git
sudo apt-add-repository ppa:ansible/ansible
sudo apt update
sudo apt install ansible
ansible --version

# Set Ansible to ignore checking host keys before connecting to target systems
cat >> ~/.ansible.cfg << EOF                                                               
[defaults]
host_key_checking = false
EOF
