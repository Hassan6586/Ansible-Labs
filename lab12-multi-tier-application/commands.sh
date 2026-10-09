#!/usr/bin/env bash
# Lab 12: Multi-tier application. Run from this folder.
cd ~/Ansible-Labs/lab12-multi-tier-application

tree roles/
ansible-inventory --graph
ansible-playbook site.yml --syntax-check
ansible-playbook site.yml --list-tasks

# Deploy all three tiers, then run again (changed=0)
ansible-playbook site.yml -K
ansible-playbook site.yml -K

# Verify each tier
redis-cli ping                           # database
curl -s http://127.0.0.1:8000/health     # app directly
curl -s http://localhost:8088/           # through nginx
curl -s http://localhost:8088/           # visits go up
systemctl status visit-counter --no-pager

# Run just one tier with tags
ansible-playbook site.yml -K --tags application
ansible-playbook site.yml -K --tags verify

# Change a setting in one tier and watch only its handler run
ansible-playbook site.yml -K --tags database -e database_maxmemory=128mb
redis-cli config get maxmemory

# Clean up
ansible-playbook cleanup.yml -K
