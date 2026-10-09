#!/usr/bin/env bash
# Lab 01: Introduction to Ansible. Every command from README.md, in order.
# Read the README first; run these one by one rather than all at once.

# --- Step 1: install Ansible (Ubuntu 22.04 / 24.04) ---
sudo apt update
sudo apt install -y software-properties-common
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install -y ansible
ansible --version

# --- Step 2: let Ansible reach this machine over SSH ---
sudo apt install -y openssh-server
sudo systemctl enable --now ssh
ssh-keygen -t ed25519 -f ~/.ssh/ansible_key -N ""
cat ~/.ssh/ansible_key.pub >> ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
ssh -i ~/.ssh/ansible_key -o StrictHostKeyChecking=accept-new "$USER@127.0.0.1" hostname

# --- Step 3: look at the inventory (run inside this folder) ---
cd ~/Ansible-Labs/lab01-introduction-to-ansible
ansible-inventory --graph
ansible all --list-hosts

# --- Step 4: ad-hoc commands ---
ansible all -m ping
ansible all -m command -a "uptime"
ansible local -m setup -a "filter=ansible_distribution*"
ansible remote -m copy -a "content='Hello from Ansible\n' dest=/tmp/hello.txt"
ansible remote -m command -a "cat /tmp/hello.txt"
ansible local -m apt -a "name=tree state=present" --become --ask-become-pass

# --- Clean up ---
ansible remote -m file -a "path=/tmp/hello.txt state=absent"
