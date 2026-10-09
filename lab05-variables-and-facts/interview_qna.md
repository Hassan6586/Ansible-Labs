# Lab 05: Interview questions

**1. What are Ansible facts, and how are they collected?**
System information about a managed host (OS, network, memory, disks), collected by the `setup` module at the start
of a play when `gather_facts` is true, and stored in `ansible_facts`.

**2. Name five places you can define variables.**
Role defaults, inventory (`group_vars`/`host_vars`), play `vars`, `vars_files`, `register`/`set_fact`, and extra
vars with `-e`.

**3. Which variable source has the highest precedence?**
Extra vars (`-e`). Role defaults have the lowest.

**4. What is the difference between `register` and `set_fact`?**
`register` stores a task's result. `set_fact` creates a variable from any expression. Both last for the rest of the
playbook run, for that host.

**5. How do you provide a default when a variable may be missing?**
With the `default` filter: `{{ port | default(8080) }}`.

**6. How do you write a condition?**
With `when:`, a raw Jinja2 expression without braces, such as `when: ansible_facts['os_family'] == "Debian"`.
Several conditions in a list are combined with AND.

**7. What are magic variables? Give examples.**
Variables Ansible sets itself: `inventory_hostname`, `group_names`, `groups`, `hostvars`, `ansible_play_hosts`.

**8. How can one host read another host's variables or facts?**
Through `hostvars`, for example `hostvars['db1']['ansible_facts']['default_ipv4']['address']`.

**9. How do you speed up plays that don't need facts?**
Set `gather_facts: false`, gather only a subset with `gather_subset`, or enable fact caching.

**10. What does `changed_when: false` do, and why use it?**
It stops a task from reporting `changed`. Use it on read-only commands so the recap stays accurate and idempotence
checks pass.
