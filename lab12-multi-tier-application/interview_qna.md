# Lab 12: Interview questions

**1. How would you structure a playbook for a three-tier app?**
One role per tier and a `site.yml` with a play per inventory group, ordered by dependency: database, then
application, then web. Group variables hold per-environment settings.

**2. Why order the plays database → app → web?**
Each tier depends on the one below it. Starting the app before the database exists would fail its health check.

**3. What does `meta: flush_handlers` do, and why use it here?**
It runs any pending handlers immediately instead of at the end of the play, so the app restarts with its new code
before the health check runs.

**4. How do tags help in day-to-day operations?**
They let you run just part of a large playbook (`--tags database`) or skip parts (`--skip-tags verify`), which is
faster and safer for small changes.

**5. Why run the app as a dedicated system user?**
Least privilege: if the app is compromised, the attacker gets a user with no shell and no access to other files.

**6. How do you validate a config file before reloading a service?**
Run the service's own test (`nginx -t`, `sshd -t`) as a task before the reload, or use the `validate:` parameter on
`template`/`copy`.

**7. How would you do a zero-downtime update of the app tier across several servers?**
Use `serial: 1` (or a percentage) on the app play, take each server out of the load balancer, update it, health
check, and put it back.

**8. How would the web tier find the app servers' addresses automatically?**
Loop over `groups['appservers']` in the nginx template and read each host's IP from
`hostvars[host]['ansible_facts']['default_ipv4']['address']`.

**9. What is the difference between `reloaded` and `restarted` for a service?**
`reloaded` asks the service to reread its config without dropping connections (nginx supports this); `restarted`
stops and starts it.

**10. How do you test the whole stack after deployment?**
An end-to-end check through the entry point (`uri` to the web tier), asserting the response proves every tier works.
