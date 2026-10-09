#!/usr/bin/env bash
# Lab 19: Hybrid cloud automation. Both hosts are your own machine. No sudo needed.
cd ~/Ansible-Labs/lab19-hybrid-cloud-automation

# Inventory
ansible-inventory --graph
ansible-inventory --host cloud-web
ansible-inventory --host local-db

# Run the hybrid playbook
ansible-playbook hybrid-deploy.yml

# Results
find /tmp/lab19 -type f | sort
cat /tmp/lab19/cloud-web/app.env
cat /tmp/lab19/local-db/database.conf
cat /tmp/lab19/local-db/firewall-allow.txt

# One environment only
ansible-playbook hybrid-deploy.yml --limit cloud
ansible cloud -m ansible.builtin.debug -a "var=log_shipping"
ansible onpremises -m ansible.builtin.debug -a "var=log_shipping"

# Clean up
ansible-playbook cleanup.yml
