#!/usr/bin/env bash
# Lab 11: CI/CD with Jenkins and Ansible.
cd ~/Ansible-Labs/lab11-cicd-with-jenkins

# 1. Try the deployment by hand first (simulating three builds)
ansible-playbook playbooks/deploy-webapp.yml --syntax-check
ansible-playbook playbooks/deploy-webapp.yml --check --diff -e build_number=1
ansible-playbook playbooks/deploy-webapp.yml -e build_number=1 -e git_commit=abc1234
ansible-playbook playbooks/deploy-webapp.yml -e build_number=2 -e git_commit=def5678
ansible-playbook playbooks/deploy-webapp.yml -e build_number=3 -e git_commit=0a1b2c3
ansible-playbook playbooks/deploy-webapp.yml -e build_number=4 -e git_commit=9f8e7d6
ls ~/webapp/releases            # only 2 3 4 are kept
readlink ~/webapp/current       # .../releases/4
cat ~/webapp/current/version.txt

# Roll back by pointing "current" at an older release
ln -sfn ~/webapp/releases/3 ~/webapp/current && cat ~/webapp/current/version.txt
rm -rf ~/webapp                 # reset before Jenkins runs it

# 2. Jenkins (see README for installation) needs Ansible for the jenkins user
sudo -u jenkins ansible --version

# 3. After the first successful Jenkins build
sudo cat /var/lib/jenkins/webapp/current/version.txt

# Clean up
sudo rm -rf /var/lib/jenkins/webapp
