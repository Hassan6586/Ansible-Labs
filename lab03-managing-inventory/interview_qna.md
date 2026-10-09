# Lab 03: Interview questions

**1. What's the difference between static and dynamic inventory?**
A static inventory is a file you maintain by hand. A dynamic inventory is generated at runtime by a script or
plugin that queries a source of truth such as AWS, Azure, VMware or a CMDB, so it stays current automatically.

**2. What are the two default groups every inventory has?**
`all` (every host) and `ungrouped` (hosts that aren't in any other group).

**3. Where can `group_vars` and `host_vars` live?**
Next to the inventory file, or next to the playbook. Playbook-adjacent ones take priority over inventory-adjacent
ones.

**4. If a variable is set in `group_vars/all`, `group_vars/webservers` and `host_vars/web1`, which wins for web1?**
`host_vars/web1`. Host variables beat group variables, and child groups beat parent groups.

**5. What does `ansible-inventory --graph` show? And `--host`?**
`--graph` shows the group tree. `--host NAME` shows the final merged variables for one host.

**6. Explain the host patterns `a:b`, `a:!b` and `a:&b`.**
Union (in a or b), exclusion (in a but not b), and intersection (in both a and b).

**7. What must a dynamic inventory script output?**
JSON with groups (each with `hosts`, optional `vars` and `children`) and ideally a `_meta.hostvars` section with
every host's variables, when called with `--list`.

**8. What is the difference between `inventory_hostname` and `ansible_host`?**
`inventory_hostname` is the name in the inventory (`web1`). `ansible_host` is the address Ansible actually connects
to (`192.168.1.10`).

**9. How do you run a playbook against only one host?**
`ansible-playbook site.yml --limit web1`.

**10. Can you use several inventories at once?**
Yes: pass `-i` multiple times, or point `-i` at a directory and Ansible loads every inventory source inside it.
