# Lab 07: Interview questions

**1. What does idempotent mean in Ansible?**
Running a task or playbook many times leaves the system in the same state as running it once. After the first run,
further runs report `changed=0`.

**2. Why are `command` and `shell` not idempotent by default?**
Ansible can't know what an arbitrary command does, so it assumes the command changed something and always reports
`changed`.

**3. How do you make a `command` task idempotent?**
Use `creates:` or `removes:`, set `changed_when:` based on the output, or replace it with a dedicated module.

**4. What is configuration drift?**
When a server's real state moves away from its defined state, usually through manual changes. Re-running an
idempotent playbook detects and corrects it.

**5. How do you test that a role is idempotent?**
Run it twice and assert the second run has `changed=0`. Molecule automates this in its `idempotence` step.

**6. `lineinfile` vs `blockinfile` vs `template`: when do you use each?**
`lineinfile` for single lines, `blockinfile` for a managed block of lines, `template` when Ansible should own the
whole file (the most predictable option).

**7. What does `changed_when: false` do?**
It forces a task to report `ok` instead of `changed`, which is correct for read-only commands.

**8. Is a `service: state=restarted` task idempotent?**
No. It restarts every time. Use `state: started` for the desired state, and trigger restarts through handlers only
when configuration changes.

**9. What is the difference between `creates` and `removes`?**
`creates: PATH` skips the command if PATH exists. `removes: PATH` runs it only if PATH exists.

**10. Why does idempotence matter for CI/CD?**
It lets pipelines run playbooks on every commit safely: repeat runs don't restart services or duplicate config,
and any reported change is a real change.
