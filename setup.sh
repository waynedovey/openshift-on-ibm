#!/bin/bash

# Setup all nodes
ansible-playbook -i inventory setup-nodes.yml -u root -k
# Validate Nodes
ansible all -i inventory -m ping -u root
# Copy Hosts files
ansible all -m copy -a "src=files/hosts dest=/etc/hosts"
# Enable Roles
mkdir -p roles
ansible-galaxy install openstack.redhat-subscription --roles-path roles/
ansible-galaxy init roles/openshift-prep

# Sub the Nodes
ansible-playbook -i inventory subscribe-ibm-nodes.yml --extra-vars=@./vars.yml
ansible-playbook -i inventory subscribe-ibm-lpar.yml --extra-vars=@./vars.yml

# Set up Packages
ansible-playbook -i inventory setup-packages.yml --extra-vars=@./vars.yml --tags "install"
