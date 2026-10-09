# Lab 10: Ansible with Kubernetes

Ansible can talk to the Kubernetes API just like `kubectl` does. That lets one tool set up the servers, the
cluster and the apps running on it, all with the same playbook style.

## 🎯 What you'll learn

- Creating a local Kubernetes cluster with **kind** (Kubernetes in Docker)
- The `kubernetes.core.k8s` module: inline definitions and manifest files
- Waiting for resources to become ready with `wait` and `wait_condition`
- Reading cluster state with `k8s_info`
- Deleting everything by removing the namespace

## 🧠 Key ideas in plain words

| Term | What it means |
| --- | --- |
| **kind** | Runs a whole Kubernetes cluster inside Docker containers. Perfect for labs. |
| **kubeconfig** | The file (`~/.kube/config`) that tells `kubectl`, and Ansible, which cluster to use. |
| **`kubernetes.core.k8s`** | Creates, updates or deletes any Kubernetes object, like `kubectl apply`/`delete`. |
| **`k8s_info`** | Reads objects, like `kubectl get`. |
| **Namespace** | A folder for Kubernetes objects. Deleting it deletes everything inside. |

Ansible runs these modules **on your machine** (`hosts: local`), and they talk to the cluster's API. Nothing is
installed on the cluster nodes.

## ✅ Before you start

- Docker installed (Lab 08). Log out and back in after Lab 08 so `docker ps` works without sudo.
- The virtual environment from Lab 09 Step 1
- 2 CPUs and 4 GB RAM free

```bash
cd ~/Ansible-Labs/lab10-ansible-with-kubernetes
```

## 🛠 Step 1: Install kubectl and kind

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -m 0755 kubectl /usr/local/bin/kubectl && rm kubectl

curl -Lo kind https://kind.sigs.k8s.io/dl/v0.33.0/kind-linux-amd64
sudo install -m 0755 kind /usr/local/bin/kind && rm kind
```

## 🛠 Step 2: Create a cluster

```bash
kind create cluster --name ansible-lab
kubectl get nodes
```

```text
NAME                        STATUS   ROLES           AGE   VERSION
ansible-lab-control-plane   Ready    control-plane   40s   v1.3x.x
```

## 🛠 Step 3: Python library and collection

```bash
source ~/ansible-cloud-venv/bin/activate
pip install kubernetes
ansible-galaxy collection install -r requirements.yml
```

## 🛠 Step 4: A namespace and a Pod

`deploy-pod.yml` writes the Kubernetes YAML **inline** under `definition:`:

```yaml
- name: Create the namespace
  kubernetes.core.k8s:
    api_version: v1
    kind: Namespace
    name: ansible-lab
    state: present

- name: Deploy an nginx Pod (definition written inline)
  kubernetes.core.k8s:
    state: present
    wait: true
    definition:
      apiVersion: v1
      kind: Pod
      metadata:
        name: nginx-app-pod
        namespace: ansible-lab
      spec:
        containers:
          - name: nginx
            image: nginx:1.27-alpine
```

```bash
ansible-playbook deploy-pod.yml
kubectl get pods -n ansible-lab
```

## 🛠 Step 5: A Deployment and Service from files

Usually your manifests already live in files. `deploy-app.yml` applies them with `src:` and waits until the
Deployment is **Available**:

```yaml
- name: Apply the Deployment
  kubernetes.core.k8s:
    state: present
    src: manifests/web-deployment.yml
    wait: true
    wait_condition:
      type: Available
      status: "True"

- name: List the Pods that belong to the app
  kubernetes.core.k8s_info:
    kind: Pod
    namespace: ansible-lab
    label_selectors:
      - app=web
  register: web_pods
```

```bash
ansible-playbook deploy-app.yml
ansible-playbook deploy-app.yml      # second run: changed=0
```

```text
TASK [Show each Pod's name and phase]
ok: [localhost] => (item=web-6d4b9c8f7-abcde)
    msg: 'web-6d4b9c8f7-abcde: Running'
ok: [localhost] => (item=web-6d4b9c8f7-fghij)
    msg: 'web-6d4b9c8f7-fghij: Running'
```

## 🔍 Verify

```bash
kubectl get all -n ansible-lab
kubectl port-forward -n ansible-lab service/web 8081:80 &
sleep 2 && curl -s http://localhost:8081 | grep title      # <title>Welcome to nginx!</title>
kill %1
```

## 🧪 Try it yourself

1. Add a `ConfigMap` with an inline definition and mount it into the Pod.
2. Change `replicas` in `manifests/web-deployment.yml` to 3 and run `deploy-app.yml` again.
3. Use `kubernetes.core.k8s_info` to list every namespace in the cluster.

## 🧹 Clean up

```bash
ansible-playbook cleanup.yml
```

Keep the kind cluster for Lab 18. To delete it: `kind delete cluster --name ansible-lab`.

➡️ **Next:** [Lab 11: CI/CD with Jenkins](../lab11-cicd-with-jenkins/)
