# Lab 02: Interview questions

**1. What is the difference between a playbook, a play and a task?**
A playbook is a YAML file containing one or more plays. A play maps a group of hosts to a list of tasks. A task
calls a single module.

**2. What does `gather_facts` do? When would you turn it off?**
It runs the `setup` module first to collect system information (OS, IPs, memory) into `ansible_facts`. Turn it
off (`gather_facts: false`) to save time when you don't use facts.

**3. What is the difference between `state: present` and `state: latest` in the `apt` module?**
`present` installs the package if it's missing and leaves the installed version alone. `latest` upgrades it to the
newest version on every run, which can cause unplanned upgrades.

**4. What does `--check` do? What are its limits?**
It runs the playbook in dry-run mode and reports what would change. Tasks that depend on earlier changes, and
`command`/`shell` tasks, can't predict their result accurately.

**5. What does `--diff` show?**
The before-and-after content of files and templates that would change. It's often combined with `--check`.

**6. How do you run only part of a playbook?**
With tags (`--tags`, `--skip-tags`), `--start-at-task "Task name"`, or `--limit` to restrict hosts.

**7. Why use FQCNs like `ansible.builtin.copy`?**
They say exactly which collection a module comes from, avoiding name clashes, and `ansible-lint` recommends them.

**8. What does `become` do, and which methods can it use?**
It runs tasks as another user, root by default. The default method is `sudo`; others include `su`, `doas` and
`runas` (Windows).

**9. Why does `apt` take a list in `name:` instead of using a loop?**
Passing a list installs all packages in a single apt transaction, which is faster than one call per package.

**10. What is the PLAY RECAP?**
The per-host summary at the end of a run: how many tasks were ok, changed, unreachable, failed, skipped, rescued
or ignored.
