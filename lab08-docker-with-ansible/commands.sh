#!/usr/bin/env bash
# Lab 08: Docker with Ansible. Run from this folder.
cd ~/Ansible-Labs/lab08-docker-with-ansible

# 1. Collections (already included if you installed the full "ansible" package)
ansible-galaxy collection install -r requirements.yml
ansible-galaxy collection list community.docker

# 2. Install Docker
ansible-playbook install-docker.yml -K
docker --version
sudo docker ps

# 3. Deploy the container, twice (second run: changed=0)
ansible-playbook deploy_containers.yml -K
ansible-playbook deploy_containers.yml -K

# 4. Verify
curl -s http://localhost:8080 | grep h1
sudo docker ps --filter name=lab-nginx
sudo docker inspect lab-nginx --format '{{ .HostConfig.RestartPolicy.Name }}'

# 5. Change the page and redeploy (only the template changes)
ansible-playbook deploy_containers.yml -K -e page_heading="Version 2 deployed by Ansible"
curl -s http://localhost:8080 | grep h1

# 6. Clean up
ansible-playbook cleanup.yml -K
