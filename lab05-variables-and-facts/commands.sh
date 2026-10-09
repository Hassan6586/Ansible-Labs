#!/usr/bin/env bash
# Lab 05: Variables and facts. Run from this folder. No sudo needed.
cd ~/Ansible-Labs/lab05-variables-and-facts

# Explore facts with ad-hoc commands
ansible local -m setup | less
ansible local -m setup -a "filter=ansible_memtotal_mb"
ansible local -m setup -a "filter=ansible_default_ipv4"

# Variables
ansible-playbook variables.yml
ansible-playbook variables.yml -e greeting="Hello from the command line"
ansible-playbook variables.yml -e "@vars/app.yml"

# Facts and conditions
ansible-playbook fact-deployment.yml
ansible-playbook fact-deployment.yml -e min_ram_mb=999999   # force the low-RAM warning
cat /tmp/lab05-system-report.txt

# Clean up
rm -f /tmp/lab05-system-report.txt
