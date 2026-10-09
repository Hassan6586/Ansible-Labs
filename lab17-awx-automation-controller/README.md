# Lab 17: AWX (Automation Controller)

So far you've run Ansible from a terminal. In a team that gets messy: who ran what, with which variables,
and where are the passwords? **AWX** puts a web UI and an API in front of Ansible. You click "Launch" (or a
pipeline calls the API), and AWX records every run, its output and who started it.

| Name | What it is |
| --- | --- |
| **AWX** | The free, open-source project. This lab installs it. |
| **Ansible Tower** | The old name for Red Hat's paid version of AWX. |
| **Automation Controller** | Tower's current name, part of **Red Hat Ansible Automation Platform (AAP)**. |

What you learn here works the same way in AAP.

> ℹ️ The old way to install AWX (an `inventory` file plus `docker-compose`) was removed years ago. Today AWX is
> installed on Kubernetes with the **AWX Operator**. This lab uses operator **2.19.1**, which installs
> AWX 24.6.1. New AWX releases have been paused while the project is restructured, so this is still the
> current install method.

## 🎯 What you'll learn

- Install the AWX Operator and an AWX instance on minikube
- Log in and find your admin password
- The AWX building blocks: **Organization → Project → Inventory → Credential → Job Template → Job**
- Run a playbook from your own GitHub repository
- (Bonus) Configure AWX as code with the `awx.awx` collection

## 🧠 Key ideas in plain words

| AWX term | Plain meaning |
| --- | --- |
| **Project** | A Git repository full of playbooks (this repo!) |
| **Inventory** | The list of hosts, same as `inventory.ini` but stored in AWX |
| **Credential** | A safely stored secret: SSH key, cloud keys, vault password |
| **Job Template** | "Run *this* playbook on *this* inventory with *these* credentials" |
| **Job** | One run of a job template, with its full output saved |
| **Operator** | A program inside Kubernetes that installs and looks after an app for you |

## ✅ Before you start

AWX is heavy. You need:

- **4 CPUs and 8 GB RAM** free for the VM or laptop (more is better)
- Docker (see [Lab 8](../lab08-docker-with-ansible/))
- `kubectl` and **minikube** (installed below)
- `git` (kustomize uses it to download the operator)
- This repository pushed to **your own GitHub account** (AWX pulls the playbook from there)

Install minikube and kubectl (Linux x86_64):

```bash
curl -LO https://github.com/kubernetes/minikube/releases/download/v1.39.0/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm minikube-linux-amd64

curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install kubectl /usr/local/bin/kubectl && rm kubectl

minikube version
kubectl version --client
```

```bash
cd ~/Ansible-Labs/lab17-awx-automation-controller
```

## 🛠 Step 1: Start a Kubernetes cluster

```bash
minikube start --cpus=4 --memory=8g --driver=docker
kubectl get nodes
```

```text
NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   40s   v1.3x.x
```

## 🛠 Step 2: Install the AWX Operator

`operator/kustomization.yaml` tells kustomize which operator version to install, and where:

```yaml
resources:
  - github.com/ansible/awx-operator/config/default?ref=2.19.1
images:
  - name: quay.io/ansible/awx-operator
    newTag: 2.19.1
namespace: awx
```

```bash
kubectl apply -k operator/
kubectl -n awx get pods
```

Wait until the operator pod shows `2/2 Running` (about a minute):

```text
NAME                                               READY   STATUS    RESTARTS   AGE
awx-operator-controller-manager-6c8f6d5b7d-x2x9k   2/2     Running   0          60s
```

## 🛠 Step 3: Ask the operator for an AWX instance

`awx.yml` is tiny. The operator does the rest:

```yaml
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx-demo
  namespace: awx
spec:
  service_type: nodeport
  nodeport_port: 30080
```

```bash
kubectl apply -f awx.yml
kubectl -n awx get pods -w      # press Ctrl+C when everything is Running
```

This takes **5 to 10 minutes** the first time (it downloads several images). At the end you'll see:

```text
NAME                                               READY   STATUS      RESTARTS   AGE
awx-demo-migration-24.6.1-abcde                    0/1     Completed   0          4m
awx-demo-postgres-15-0                             1/1     Running     0          5m
awx-demo-task-7d9c9b7d8b-k2j4p                     4/4     Running     0          5m
awx-demo-web-5b7c8d9f6c-q8w7z                      3/3     Running     0          5m
awx-operator-controller-manager-6c8f6d5b7d-x2x9k   2/2     Running     0          7m
```

Want to see what the operator is doing? Follow its log:

```bash
kubectl -n awx logs -f deployments/awx-operator-controller-manager -c awx-manager
```

## 🛠 Step 4: Log in

The admin password is generated for you and stored in a Kubernetes secret:

```bash
kubectl -n awx get secret awx-demo-admin-password -o jsonpath="{.data.password}" | base64 --decode; echo
```

Get the URL:

```bash
minikube service awx-demo-service -n awx --url
```

```text
http://192.168.49.2:30080
```

Open it in a browser and log in as **admin** with that password.

> 💡 On macOS/Windows with the Docker driver, that command opens a tunnel and must stay running. Keep the
> terminal open, or use `kubectl -n awx port-forward svc/awx-demo-service 8043:80` and browse to
> `http://localhost:8043`.

## 🛠 Step 5: Run a playbook from your repository

The playbook AWX will run is `awx-demo/hello.yml`:

```yaml
- name: Hello from AWX
  hosts: all
  tasks:
    - name: Say hello
      ansible.builtin.debug:
        msg: "{{ greeting }}! This job ran on {{ inventory_hostname }} ..."
    - name: Show the variables AWX passed in
      ansible.builtin.debug:
        msg:
          - "Job ID: {{ awx_job_id | default('not running in AWX') }}"
          - "Launched by: {{ awx_user_name | default('unknown') }}"
```

You can test it locally first: `ansible-playbook -i inventory.ini awx-demo/hello.yml`.

In the AWX UI (left menu → **Resources**):

1. **Projects → Add**
   - Name: `Ansible Labs`
   - Source control type: `Git`
   - Source control URL: `https://github.com/<your-user>/Ansible-Labs.git`
   - Branch: `main`, and tick **Update revision on launch**
   - Save. Wait for the status to turn green (**Successful**).
2. **Inventories → Add → Add inventory**
   - Name: `Lab 17 Inventory` → Save
   - **Hosts** tab → Add → Name: `localhost`, Variables:

     ```yaml
     ansible_connection: local
     ```

3. **Templates → Add → Add job template**
   - Name: `Hello from AWX`
   - Inventory: `Lab 17 Inventory`
   - Project: `Ansible Labs`
   - Playbook: `lab17-awx-automation-controller/awx-demo/hello.yml`
   - Variables: `greeting: Hello from the AWX UI`
   - Save
4. Click **Launch** 🚀

The job output looks just like your terminal:

```text
TASK [Say hello] ***************************************************************
ok: [localhost] => {
    "msg": "Hello from the AWX UI! This job ran on localhost (CentOS Stream 9)."
}

TASK [Show the variables AWX passed in] ****************************************
ok: [localhost] => {
    "msg": [
        "Job ID: 4",
        "Launched by: admin",
        "Template: Hello from AWX"
    ]
}
```

> 💡 **Why CentOS?** `localhost` here is the **execution environment**: a container that AWX starts for every
> job (the default `awx-ee` image is CentOS Stream based). It isn't your laptop. To manage real servers, add their IPs to the inventory and an SSH key under
> **Credentials → Machine**.

Look around: **Views → Jobs** keeps every run, who launched it, the exact Git commit and the full output.

## 🛠 Step 6 (bonus): Configure AWX as code

Clicking is fine for learning. In real teams the AWX setup itself lives in Git. `configure-awx.yml` creates
the same project, inventory, host and template with the `awx.awx` collection, then launches the job:

```bash
ansible-galaxy collection install awx.awx

export CONTROLLER_HOST=$(minikube service awx-demo-service -n awx --url)
export CONTROLLER_USERNAME=admin
export CONTROLLER_PASSWORD=$(kubectl -n awx get secret awx-demo-admin-password -o jsonpath="{.data.password}" | base64 --decode)

ansible-playbook configure-awx.yml -e repo_url=https://github.com/<your-user>/Ansible-Labs.git
```

```text
TASK [Show the job result] *****************************************************
ok: [localhost] =>
    msg: 'Job 5 finished with status: successful'
```

Running it again changes nothing (it's idempotent), except for launching another job.

## 🧪 Try it yourself

1. Tick **Prompt on launch** for Variables, and launch with `greeting: Salam from AWX`.
2. Add a **Schedule** to the template so it runs every hour.
3. Create a **Survey** (a form shown at launch) with a text field called `greeting`.
4. Create a second template for `lab15-jinja2-templates/render-templates.yml`, then link both in a
   **Workflow Template**.
5. Create a user with only **Execute** permission on the template. Log in as them: they can run it but not
   change it.

## 🔍 Verify

```bash
kubectl -n awx get awx                 # awx-demo exists
kubectl -n awx get pods                # web, task and postgres pods are Running
```

In the UI, **Views → Jobs** shows your job with a green **Successful** status.

## 🧹 Clean up

Remove only AWX:

```bash
kubectl delete -f awx.yml
kubectl delete -k operator/
```

Or delete the whole minikube cluster:

```bash
minikube delete
```

➡️ **Next:** [Lab 18: Kubernetes scaling and lifecycle](../lab18-kubernetes-scaling-and-lifecycle/)
