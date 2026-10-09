#!/usr/bin/env bash
# Lab 04: Using Ansible roles. Run from this folder.
cd ~/Ansible-Labs/lab04-ansible-roles

# (Optional) see the skeleton ansible-galaxy would generate for a new role
ansible-galaxy role init /tmp/demo_role && tree /tmp/demo_role && rm -rf /tmp/demo_role

# Look at our role
tree roles/

# Check, then run the playbook
ansible-playbook webserver-playbook.yml --syntax-check
ansible-playbook webserver-playbook.yml -K
ansible-playbook webserver-playbook.yml -K        # second run: changed=0

# Verify
curl -s http://localhost | grep -E "<h1>|Host:"
systemctl is-active apache2

# Change a variable from the command line and watch the handler run
ansible-playbook webserver-playbook.yml -K -e webserver_owner="Your Name"
curl -s http://localhost | grep Owner

# Clean up (frees port 80)
ansible-playbook cleanup.yml -K
