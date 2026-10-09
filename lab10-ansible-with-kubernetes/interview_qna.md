# Lab 10: Interview questions

**1. Which collection manages Kubernetes from Ansible?**
`kubernetes.core`. Its main modules are `k8s` (create, update, delete), `k8s_info` (read), `k8s_scale`,
`k8s_rollback`, `k8s_exec`, `k8s_log` and `helm`.

**2. Where do Kubernetes modules run, and what do they need?**
On the control node (usually `hosts: localhost`). They need the `kubernetes` Python library and a kubeconfig or API
credentials.

**3. How does `k8s` choose which cluster to talk to?**
From `~/.kube/config` and its current context by default, or from `kubeconfig:`, `context:`, `host:` and
`api_key:` parameters, or the `K8S_AUTH_*` environment variables.

**4. What is the difference between `definition:` and `src:`?**
`definition:` holds the resource inline in the playbook (and can use Jinja2 variables); `src:` points to a manifest
file.

**5. How do you wait for a Deployment to be ready?**
Set `wait: true`, optionally with `wait_condition` (`type: Available`, `status: "True"`) and `wait_timeout`.

**6. Why use Ansible instead of plain `kubectl apply`?**
To combine cluster work with everything else (provisioning, secrets from Vault, templating per environment, waiting
and verification) in one idempotent, reviewable workflow.

**7. How would you deploy a Helm chart with Ansible?**
With `kubernetes.core.helm` (and `helm_repository` to add the repo), passing chart values as variables.

**8. What is kind, and when would you use it?**
Kubernetes IN Docker: a full cluster inside containers. It's ideal for local testing and CI, not production.

**9. How do you remove everything an app created?**
Delete its namespace with `k8s` `state: absent` (wait: true), which removes everything inside it.

**10. How would you template a manifest for dev and prod?**
Keep it as a Jinja2 template and pass `definition: "{{ lookup('ansible.builtin.template', 'deploy.yml.j2') | from_yaml }}"`,
with different variables per environment in `group_vars`.
