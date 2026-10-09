#!/usr/bin/env bash
# Lab 16: Loops and advanced playbooks. Run from this folder.
# Task 2 creates users with sudo; add -K if sudo asks you for a password.
cd ~/Ansible-Labs/lab16-loops-and-advanced-playbooks

# Run every loop example
ansible-playbook loops.yml

# Look before you run
ansible-playbook loops.yml --list-tasks
ansible-playbook loops.yml --list-tags

# Run only some parts
ansible-playbook loops.yml --tags dicts
ansible-playbook loops.yml --tags basics,nested
ansible-playbook loops.yml --skip-tags users

# Verify
find /tmp/lab16
cat /tmp/lab16/config/app.ini
cat /tmp/lab16/envs/dev/settings.env
id deployer

# Clean up (removes the users and /tmp/lab16)
ansible-playbook cleanup.yml
