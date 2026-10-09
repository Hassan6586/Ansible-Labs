# Lab 10: Troubleshooting

| Problem | Why it happens | Fix |
| --- | --- | --- |
| `Failed to import the required Python library (kubernetes)` | The modules run with a Python that lacks the library. | `source ~/ansible-cloud-venv/bin/activate && pip install kubernetes`, and run from this folder. |
| `kind: permission denied while trying to connect to the Docker daemon` | Your user isn't in the `docker` group yet. | Log out and back in after Lab 08 (or `newgrp docker`). |
| `Invalid kube-config file. No configuration found.` | No cluster exists or `~/.kube/config` is missing. | `kind create cluster --name ansible-lab`; check `kubectl config current-context`. |
| `Failed to get client due to HTTPConnectionPool ... Connection refused` | The cluster's Docker container stopped (for example after a reboot). | `docker start ansible-lab-control-plane`, or recreate the cluster. |
| `wait_condition` times out | Pods can't start: image pull problems or too little memory. | `kubectl describe pod -n ansible-lab <name>` and read the Events at the bottom. |
| `ImagePullBackOff` | Wrong image name or no internet access. | Check the image tag; test with `docker pull nginx:1.27-alpine`. |
| A task reports `changed` every run | A field in your manifest differs from what the cluster stores (for example a server-set default). | Compare with `kubectl get ... -o yaml`; use `apply: true` for client-side apply behavior. |
