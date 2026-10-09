# Lab 18: Kubernetes scaling and lifecycle

In Lab 10 you put an app on Kubernetes. Real apps then live a whole life: they get **more traffic** (scale
up), get **new versions** (rolling update), sometimes a new version is **broken** (roll back), and one day they
are **removed**. This lab walks one Deployment through that whole life with Ansible.

```text
create (1.27, 2 pods) ─► scale (5 pods) ─► update (1.28) ─► roll back (1.27) ─► delete
```

## 🎯 What you'll learn

- Keep a Deployment manifest as a **Jinja2 template** and apply it with `kubernetes.core.k8s`
- Scale with `kubernetes.core.k8s_scale` and wait for the new pods
- Zero-downtime rolling updates (`maxSurge`, `maxUnavailable`, readiness probes)
- Roll back with `kubernetes.core.k8s_rollback`
- Why the manifest is the "source of truth" (and how that can surprise you)

## 🧠 Key ideas in plain words

| Term | What it means |
| --- | --- |
| **Deployment** | Keeps N copies (replicas) of your pod running and handles updates |
| **ReplicaSet** | One version of a Deployment. Every image change creates a new one |
| **Revision** | The version number Kubernetes gives each ReplicaSet (1, 2, 3...) |
| **Rolling update** | Replace pods a few at a time so the app never goes down |
| **Readiness probe** | Kubernetes only sends traffic to a pod after this check passes |
| **Rollback** | Make the previous ReplicaSet the active one again |

## ✅ Before you start

- The kind cluster from [Lab 10](../lab10-ansible-with-kubernetes/) (`kind get clusters` shows `ansible-lab`).
  If it's gone: `kind create cluster --name ansible-lab`.
- The virtual environment from Lab 09 with the `kubernetes` Python library.

```bash
cd ~/Ansible-Labs/lab18-kubernetes-scaling-and-lifecycle
source ~/ansible-cloud-venv/bin/activate
ansible-galaxy collection install -r requirements.yml
kubectl get nodes
```

Files in this lab:

```text
vars.yml                      # namespace, app name, image tag, replicas
templates/deployment.yml.j2   # the Deployment, written once as a template
deploy.yml                    # create or update (Steps 2 and 4)
scale.yml                     # change the number of pods (Step 3)
rollback.yml                  # undo the last update (Step 5)
delete.yml                    # remove everything (Step 6)
tasks/show-status.yml         # prints image, replicas, revision and pods
```

## 🛠 Step 1: Read the Deployment template

The important part of `templates/deployment.yml.j2`:

```yaml
metadata:
  annotations:
    kubernetes.io/change-cause: "Ansible set image nginx:{{ image_tag }}"
spec:
  replicas: {{ replicas }}
  revisionHistoryLimit: 5          # keep 5 old versions so we can roll back
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1                  # at most 1 extra pod during an update
      maxUnavailable: 0            # never go below the wanted number of pods
  template:
    spec:
      containers:
        - name: nginx
          image: nginx:{{ image_tag }}
          readinessProbe:
            httpGet: { path: /, port: 80 }
```

`deploy.yml` applies it with the `template:` option, which renders the Jinja2 first (Lab 15) and then applies
the result:

```yaml
- name: Apply the Deployment and wait for the rollout to finish
  kubernetes.core.k8s:
    state: present
    template: deployment.yml.j2
    wait: true
    wait_timeout: 180
```

## 🛠 Step 2: Create it

```bash
ansible-playbook deploy.yml
```

```text
TASK [Apply the Deployment and wait for the rollout to finish]
changed: [localhost]

TASK [Summary]
ok: [localhost] =>
    msg:
    - 'Image:     nginx:1.27'
    - 'Replicas:  2/2 ready'
    - 'Revision:  1'
    - 'Pods:      nginx-app-7c9d8b5f4-2kq9x, nginx-app-7c9d8b5f4-wm7tz'
```

Pod names are random, so yours will differ. Run it again: `changed=0`, nothing to do.

## 🛠 Step 3: Scale up

```yaml
- name: "Scale and wait until all pods are ready: {{ replicas }}"
  kubernetes.core.k8s_scale:
    api_version: apps/v1
    kind: Deployment
    name: "{{ app_name }}"
    namespace: "{{ k8s_namespace }}"
    replicas: "{{ replicas | int }}"
    wait: true
```

```bash
ansible-playbook scale.yml                # 5 replicas
```

```text
    - 'Image:     nginx:1.27'
    - 'Replicas:  5/5 ready'
    - 'Revision:  1'
```

Scaling doesn't create a new revision: the pods are the same version, just more of them. Try
`ansible-playbook scale.yml -e replicas=3` too.

## 🛠 Step 4: Rolling update to a new version

Open a second terminal and watch the pods change while the update runs:

```bash
kubectl -n lab18 get pods -w
```

Then update the image. Pass the current replica count too (see the warning below):

```bash
ansible-playbook deploy.yml -e image_tag=1.28 -e replicas=5
```

```text
    - 'Image:     nginx:1.28'
    - 'Replicas:  5/5 ready'
    - 'Revision:  2'
```

In the second terminal you'll see new pods start, become `1/1 Running`, and only then an old pod terminate,
one at a time. That's `maxSurge: 1` and `maxUnavailable: 0` at work: there are never fewer than 5 ready pods.

> ⚠️ **The manifest wins.** `deploy.yml` says `replicas: 2` (from `vars.yml`). If you run it without
> `-e replicas=5`, Kubernetes goes back to 2 pods, undoing your scale. That's how declarative tools work: the
> file is the truth. In real projects you either keep the replica count in the file, or leave `replicas` out
> and let a HorizontalPodAutoscaler manage it.

See the history Kubernetes keeps:

```bash
kubectl -n lab18 rollout history deployment/nginx-app
```

```text
REVISION  CHANGE-CAUSE
1         Ansible set image nginx:1.27
2         Ansible set image nginx:1.28
```

## 🛠 Step 5: Roll back

Pretend 1.28 has a bug. Go back to the previous version:

```bash
ansible-playbook rollback.yml
```

```text
TASK [Roll back one revision]
changed: [localhost]

TASK [Summary]
    msg:
    - 'Image:     nginx:1.27'
    - 'Replicas:  5/5 ready'
    - 'Revision:  3'
```

The rollback re-uses the old ReplicaSet and gives it a new number, so revision 1 becomes revision 3.

> 💡 A rollback is a quick fix. Afterwards, also set `image_tag: "1.27"` in `vars.yml` (or fix the bug and
> ship 1.29). Otherwise the next `deploy.yml -e image_tag=1.28` brings the bug back.

## 🛠 Step 6: Delete everything

```bash
ansible-playbook delete.yml
kubectl get ns lab18      # Error from server (NotFound)
```

## 🧠 Ansible vs kubectl

| Task | kubectl | Ansible |
| --- | --- | --- |
| Create / update | `kubectl apply -f deploy.yml` | `kubernetes.core.k8s: state=present` |
| Scale | `kubectl scale deploy/nginx-app --replicas=5` | `kubernetes.core.k8s_scale` |
| Wait for a rollout | `kubectl rollout status deploy/nginx-app` | `wait: true` |
| Roll back | `kubectl rollout undo deploy/nginx-app` | `kubernetes.core.k8s_rollback` |
| Read state | `kubectl get deploy -o yaml` | `kubernetes.core.k8s_info` |
| Delete | `kubectl delete ns lab18` | `kubernetes.core.k8s: state=absent` |

## 🧪 Try it yourself

1. Deploy a tag that doesn't exist: `ansible-playbook deploy.yml -e image_tag=9.99 -e replicas=5`. The task
   times out, but the app stays up. Why? (`maxUnavailable: 0`: the old pods are kept until new ones are ready.)
   Fix it with `rollback.yml`.
2. Change `maxSurge` to `5` and update again. How does the pod list look now?
3. Add a `livenessProbe` to the template. What's the difference from a readiness probe?
4. Add a HorizontalPodAutoscaler with `kubernetes.core.k8s` (min 2, max 10, 70% CPU).

## 🔍 Verify

```bash
kubectl -n lab18 get deploy,rs,pods,svc
kubectl -n lab18 rollout history deployment/nginx-app
```

## 🧹 Clean up

```bash
ansible-playbook delete.yml
# Done with Kubernetes labs? Remove the cluster too:
kind delete cluster --name ansible-lab
```

➡️ **Next:** [Lab 19: Hybrid cloud automation](../lab19-hybrid-cloud-automation/)
