#!/usr/bin/env bash
# Lab 02: Writing your first playbook. Run these one by one from this folder.
cd ~/Ansible-Labs/lab02-first-playbook

# Check the playbooks for syntax errors (doesn't run anything)
ansible-playbook hello.yml --syntax-check
ansible-playbook install-multiple-packages.yml --syntax-check

# See which tasks and hosts a playbook would use
ansible-playbook install-multiple-packages.yml --list-tasks --list-hosts

# Run the first playbook, twice
ansible-playbook hello.yml
ansible-playbook hello.yml

# Dry run (check mode) with a diff, then the real run
ansible-playbook install-multiple-packages.yml --check --diff -K
ansible-playbook install-multiple-packages.yml -K
ansible-playbook install-multiple-packages.yml -K

# Verify
cat /tmp/lab02/welcome.txt
tree --version && git --version

# Clean up
rm -rf /tmp/lab02
