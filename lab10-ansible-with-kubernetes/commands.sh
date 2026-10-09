#!/usr/bin/env bash
# Lab 10: Ansible with Kubernetes. Needs Docker (Lab 08) and the virtual environment (Lab 09).
cd ~/Ansible-Labs/lab10-ansible-with-kubernetes

# 1. Tools: kubectl and kind
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -m 0755 kubectl /usr/local/bin/kubectl && rm kubectl
curl -Lo kind https://kind.sigs.k8s.io/dl/v0.33.0/kind-linux-amd64
sudo install -m 0755 kind /usr/local/bin/kind && rm kind

# 2. A local Kubernetes cluster (runs inside Docker)
kind create cluster --name ansible-lab
kubectl get nodes

# 3. Python library + collection
source ~/ansible-cloud-venv/bin/activate
pip install kubernetes
ansible-galaxy collection install -r requirements.yml

# 4. Deploy with Ansible
ansible-playbook deploy-pod.yml
ansible-playbook deploy-app.yml
ansible-playbook deploy-app.yml        # second run: changed=0

# 5. Verify with kubectl
kubectl get all -n ansible-lab
kubectl port-forward -n ansible-lab service/web 8081:80 &
sleep 2 && curl -s http://localhost:8081 | grep title
kill %1

# 6. Clean up
ansible-playbook cleanup.yml
# keep the kind cluster for Lab 18, or delete it:
# kind delete cluster --name ansible-lab
