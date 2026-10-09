#!/usr/bin/env bash
# Lab 18: Kubernetes scaling and lifecycle. Needs the kind cluster from Lab 10.
cd ~/Ansible-Labs/lab18-kubernetes-scaling-and-lifecycle
source ~/ansible-cloud-venv/bin/activate
ansible-galaxy collection install -r requirements.yml
kubectl get nodes

# Create (nginx:1.27, 2 pods)
ansible-playbook deploy.yml

# Scale up to 5 pods
ansible-playbook scale.yml
ansible-playbook scale.yml -e replicas=3   # or any number

# Rolling update to 1.28 (watch in another terminal: kubectl -n lab18 get pods -w)
ansible-playbook deploy.yml -e image_tag=1.28 -e replicas=5
kubectl -n lab18 rollout history deployment/nginx-app

# Roll back to 1.27
ansible-playbook rollback.yml

# Verify
kubectl -n lab18 get deploy,rs,pods,svc

# Clean up
ansible-playbook delete.yml
# kind delete cluster --name ansible-lab
