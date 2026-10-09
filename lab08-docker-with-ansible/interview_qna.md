# Lab 08: Interview questions

**1. What is an Ansible collection?**
A distributable package of modules, plugins, roles and playbooks, named `namespace.collection`
(for example `community.docker`). Install with `ansible-galaxy collection install`.

**2. Which collection manages Docker, and which modules did you use?**
`community.docker`: `docker_image_pull`, `docker_network`, `docker_container`, `docker_container_info` and
`docker_image_remove`.

**3. What happens if you change a container's port in the playbook and run it again?**
`docker_container` notices the difference and recreates the container with the new settings.

**4. Why pin image tags instead of using `latest`?**
For reproducibility: `latest` changes over time, so the same playbook could deploy different versions.

**5. How do you wait for a service to become healthy in Ansible?**
Use `uri` (or `wait_for`) with `register`, `until`, `retries` and `delay`.

**6. Ansible vs Docker Compose: when would you use each?**
Compose defines a multi-container app on one host. Ansible can install Docker, configure the host, deploy Compose
projects (`docker_compose_v2`) and do it across many hosts.

**7. What does `restart_policy: unless-stopped` mean?**
Docker restarts the container after crashes and reboots, unless someone stopped it on purpose.

**8. What is the difference between a bind mount and a named volume?**
A bind mount maps a specific host path into the container. A named volume is storage managed by Docker in its own
directory.

**9. How would you deploy the same container to 20 servers?**
Put the servers in an inventory group and target that group with the playbook. Ansible runs on them in parallel
(5 at a time by default; change with `forks`).

**10. How would you do a rolling update across those servers?**
Use `serial:` on the play (for example `serial: 2`) so only a few hosts are updated at a time, with a health check
after each batch.
