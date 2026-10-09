#!/usr/bin/env bash
# Lab 03: Managing inventory. Run from this folder. Nothing here connects to a server.
cd ~/Ansible-Labs/lab03-managing-inventory

# 1. INI inventory
ansible-inventory -i inventories/ini/hosts.ini --graph
ansible -i inventories/ini/hosts.ini webservers --list-hosts

# 2. YAML inventory with group_vars and host_vars (the default in ansible.cfg)
ansible-inventory --graph
ansible-inventory --graph --vars
ansible-inventory --host web1
ansible-inventory --host web2
ansible-playbook show-vars.yml

# 3. Host patterns
ansible all --list-hosts
ansible 'webservers:databases' --list-hosts      # union (OR)
ansible 'production:!databases' --list-hosts     # exclude
ansible 'production:&webservers' --list-hosts    # intersection (AND)
ansible 'web*' --list-hosts                      # wildcard
ansible all --limit web1 --list-hosts

# 4. Dynamic inventory script
./inventories/dynamic/dynamic_inventory.py --list
ansible-inventory -i inventories/dynamic/dynamic_inventory.py --graph

# 5. Several inventories at once
ansible-inventory -i inventories/production/hosts.yml -i inventories/dynamic/dynamic_inventory.py --graph
