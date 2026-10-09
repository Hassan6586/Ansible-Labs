# Lab 18: Interview questions

**1. How do you scale a Deployment with Ansible?**
With `kubernetes.core.k8s_scale` (set `replicas` and `wait: true`), or by changing `replicas` in the manifest
and applying it with `kubernetes.core.k8s`.

**2. What is a rolling update?**
Kubernetes replaces old pods with new ones gradually, so the app keeps serving traffic. It's the default
Deployment strategy; the alternative is `Recreate` (stop all, then start all).

**3. What do `maxSurge` and `maxUnavailable` control?**
`maxSurge` is how many extra pods may exist during an update; `maxUnavailable` is how many may be missing. With
`maxSurge: 1, maxUnavailable: 0`, capacity never drops.

**4. Why does a readiness probe matter for rolling updates?**
Kubernetes only counts a new pod as ready, and only removes an old pod, after the probe passes. Without it, a
broken pod could receive traffic as soon as it starts.

**5. How do you roll back a Deployment with Ansible?**
`kubernetes.core.k8s_rollback`, the equivalent of `kubectl rollout undo`. It reactivates the previous
ReplicaSet.

**6. Why does a rollback create a new revision number?**
Kubernetes always gives the active ReplicaSet the highest number. The old ReplicaSet is re-used and renumbered.

**7. What does `revisionHistoryLimit` do?**
It sets how many old ReplicaSets are kept. They're what makes rollbacks possible; 0 means no rollbacks.

**8. Why can re-running a deployment playbook undo a manual scale?**
The playbook applies the full manifest, including `replicas`. Declarative tools make the cluster match the
file. Leave `replicas` out (or manage it with an HPA) if something else should control it.

**9. What does `wait: true` do on `kubernetes.core.k8s`?**
For a Deployment, it waits until the rollout is complete and all replicas are updated and available, like
`kubectl rollout status`. `wait_timeout` limits how long.

**10. How do you record why each revision exists?**
Set the `kubernetes.io/change-cause` annotation. It shows in `kubectl rollout history`.
