#!/usr/bin/env bash
# Lab 13: Security hardening. Use a VM you can reach through a console, not your only remote server.
cd ~/Ansible-Labs/lab13-security-hardening

# Preview first
ansible-playbook ssh-hardening.yml --check --diff -K

# Apply, then apply again (changed=0)
ansible-playbook ssh-hardening.yml -K
ansible-playbook ssh-hardening.yml -K

# Audit (read-only)
ansible-playbook audit.yml -K

# Look for yourself
sudo sshd -T | grep -E "permitrootlogin|maxauthtries|x11forwarding|passwordauthentication"
sudo ufw status verbose
sudo fail2ban-client status sshd
ssh -i ~/.ssh/ansible_key "$USER@127.0.0.1" hostname     # key login still works

# Disable password logins (ONLY after the key login above works)
ansible-playbook ssh-hardening.yml -K -e hardening_ssh_disable_passwords=true

# Roll back (personal laptops / WSL)
ansible-playbook rollback.yml -K
