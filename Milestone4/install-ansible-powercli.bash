# Script used to install ansible and PowerCLI tools onto a ubuntu based system
## To Use: Download Script from this repo, then run with "sudo bash ./install-ansible-powercli.bash"

# Install Ansible Dependencies
sudo apt install sshpass python3-paramiko git
sudo apt-add-repository ppa:ansible/ansible
sudo apt update
sudo apt install ansible
ansible --version

# Install PowerShell, VSCode, remmina, and onboard
sudo snap install powershell --classic
sudo snap install code --classic
sudo apt install remmina onboard

# Set Ansible to ignore checking host keys before connecting to target systems
cat >> ~/.ansible.cfg << EOF                                                               
[defaults]
host_key_checking = false
EOF
