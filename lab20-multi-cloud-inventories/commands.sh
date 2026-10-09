#!/usr/bin/env bash
# Lab 20: Multi-cloud inventories.
cd ~/Ansible-Labs/lab20-multi-cloud-inventories
source ~/ansible-cloud-venv/bin/activate
ansible-galaxy collection install -r requirements.yml

# Offline: static file + constructed groups
ansible-inventory -i inventories/01-onprem.yml -i inventories/99-constructed.yml --graph
ansible-inventory -i inventories/01-onprem.yml -i inventories/99-constructed.yml --host onprem-db1

# With AWS credentials: the whole folder (static + aws_ec2 + constructed)
aws sts get-caller-identity
ansible-inventory --graph
ansible-inventory --graph env_production
ansible-inventory --host lab09-instance

# One playbook for every source
ansible-playbook show-inventory.yml
ansible aws -m ansible.builtin.ping --private-key ~/.ssh/lab09-key.pem

# Optional: Azure
# ansible-galaxy collection install azure.azcollection
# pip install -r ~/.ansible/collections/ansible_collections/azure/azcollection/requirements.txt
# az login
# cp optional/azure_rm.yml inventories/60-azure_rm.yml
# ansible-inventory --graph

# Clean up: terminate the Lab 09 instance so it stops costing money
ansible-playbook ../lab09-aws-ec2-provisioning/terminate-ec2.yml
