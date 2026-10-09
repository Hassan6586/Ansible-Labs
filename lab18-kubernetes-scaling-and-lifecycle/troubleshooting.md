# Lab 18: Troubleshooting

| Problem | Why it happens | Fix |
| --- | --- | --- |
| `Failed to import the required Python library (kubernetes)` | Ansible isn't running from the virtual environment. | `source ~/ansible-cloud-venv/bin/activate` (the inventory uses `ansible_playbook_python`). |
| `Invalid kube-config file` / connection refused | No cluster, or kubectl points somewhere else. | `kind get clusters`, `kubectl config current-context` (should be `kind-ansible-lab`). |
| `Could not find or access 'deployment.yml.j2'` | The template isn't in `templates/` next to the playbook. | Keep the folder layout as it is in the repo. |
| `Deployment ... not found` in `scale.yml` or `rollback.yml` | You haven't run `deploy.yml` yet, or you deleted it. | Run `ansible-playbook deploy.yml` first. |
| After `deploy.yml` there are only 2 pods again | The manifest says `replicas: 2`, and Ansible applies the manifest. | Pass `-e replicas=5`, or change `replicas` in `vars.yml`. |
| Update times out (`wait_timeout`) | The new pods never become ready (bad image tag, failing probe, not enough resources). | `kubectl -n lab18 get pods` and `kubectl -n lab18 describe pod <name>`; then `ansible-playbook rollback.yml`. |
| `ErrImagePull` / `ImagePullBackOff` | The image tag doesn't exist or Docker Hub is rate limiting. | Check the tag on Docker Hub; wait and retry. |
| Rollback says there is no previous revision | Only one revision exists (you haven't updated the image yet), or `revisionHistoryLimit` is 0. | Do Step 4 first; keep `revisionHistoryLimit` above 0. |
| Pods stay `Pending` | The kind node is out of CPU or memory. | Lower `replicas`, or give Docker more resources. |
| Namespace stuck in `Terminating` | Something inside it is still being cleaned up. | Wait a minute; `kubectl get all -n lab18` shows what's left. |
