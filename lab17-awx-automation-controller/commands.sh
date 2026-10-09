#!/usr/bin/env bash
# Lab 17: AWX with the AWX Operator on minikube.
# Needs 4 CPUs, 8 GB RAM, Docker, kubectl, minikube and git.
cd ~/Ansible-Labs/lab17-awx-automation-controller

# 1. Cluster
minikube start --cpus=4 --memory=8g --driver=docker
kubectl get nodes

# 2. Operator
kubectl apply -k operator/
kubectl -n awx get pods

# 3. AWX instance (takes 5-10 minutes)
kubectl apply -f awx.yml
kubectl -n awx get pods -w
# kubectl -n awx logs -f deployments/awx-operator-controller-manager -c awx-manager

# 4. Log in as admin
kubectl -n awx get secret awx-demo-admin-password -o jsonpath="{.data.password}" | base64 --decode; echo
minikube service awx-demo-service -n awx --url

# 5. In the UI: Project -> Inventory (+ localhost host) -> Job Template -> Launch
#    Playbook: lab17-awx-automation-controller/awx-demo/hello.yml
ansible-playbook -i inventory.ini awx-demo/hello.yml   # test the playbook locally first

# 6. Bonus: configure AWX as code
ansible-galaxy collection install awx.awx
export CONTROLLER_HOST=$(minikube service awx-demo-service -n awx --url)
export CONTROLLER_USERNAME=admin
export CONTROLLER_PASSWORD=$(kubectl -n awx get secret awx-demo-admin-password -o jsonpath="{.data.password}" | base64 --decode)
ansible-playbook configure-awx.yml -e repo_url=https://github.com/<your-user>/Ansible-Labs.git

# Clean up
kubectl delete -f awx.yml
kubectl delete -k operator/
# or everything: minikube delete
