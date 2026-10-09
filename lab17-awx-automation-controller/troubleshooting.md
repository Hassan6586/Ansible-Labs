# Lab 17: Troubleshooting

| Problem | Why it happens | Fix |
| --- | --- | --- |
| Pods stay `Pending` | Not enough CPU or memory in minikube. | `kubectl -n awx describe pod <name>` shows "Insufficient memory". Recreate: `minikube delete && minikube start --cpus=4 --memory=8g`. |
| `kubectl apply -k operator/` fails with "git: not found" | kustomize downloads the operator with git. | `sudo apt install -y git`. |
| Only the operator pod appears, no AWX pods | The AWX object wasn't created, or the operator is still working. | `kubectl -n awx get awx`, then follow the operator log (`kubectl -n awx logs -f deployments/awx-operator-controller-manager -c awx-manager`). |
| `ImagePullBackOff` | Slow or blocked internet, or Docker Hub/quay.io rate limits. | Wait and retry; check `kubectl -n awx describe pod <name>`. |
| Postgres pod in `CrashLoopBackOff` | Usually a broken volume from an earlier attempt. | `kubectl delete -f awx.yml`, `kubectl -n awx delete pvc --all`, then apply again. |
| Browser can't open the URL | With the Docker driver on macOS/Windows the node IP isn't reachable. | Keep `minikube service ... --url` running, or `kubectl -n awx port-forward svc/awx-demo-service 8043:80`. |
| `secret "awx-demo-admin-password" not found` | AWX isn't finished yet, or the name in `awx.yml` was changed. | The secret is called `<name>-admin-password`. Wait for the pods, then try again. |
| Project sync fails | Wrong URL or branch, or the repository is private. | Check the URL in a browser. For a private repo, add a **Source Control** credential with a GitHub token. |
| The playbook isn't in the template's dropdown | The project hasn't synced the latest commit, or the file isn't valid YAML with a `hosts:` line. | Sync the project again; run `ansible-playbook --syntax-check` on the file locally. |
| Job fails: `couldn't resolve module/action` | The execution environment doesn't have that collection. | Add a `collections/requirements.yml` to the repo, or use a custom execution environment. |
| Job says `Failed to connect to the host via ssh` for localhost | The host is missing `ansible_connection: local`. | Add it to the host's variables. |
