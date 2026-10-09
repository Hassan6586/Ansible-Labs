# Lab 19: Troubleshooting

| Problem | Why it happens | Fix |
| --- | --- | --- |
| `group_vars` values are ignored | The folder isn't next to the inventory (or the playbook), or the file name doesn't match the group name. | Keep `group_vars/` beside `inventory.yml`; `cloud.yml` must match the group `cloud`. |
| `'location' is undefined` for one host | That host's group has no file defining it. | Define it in every group file, or give a default in `group_vars/all.yml`. |
| `hostvars['local-db']` has no `private_ip` | The host name in `hostvars[...]` is spelled differently from the inventory. | Use `groups['onpremises'][0]` instead of typing the name. |
| `hostvars[...]['ansible_facts']` is empty | Facts are only there for hosts that gathered them in this run. | Gather facts for that host first, or use inventory variables like `private_ip`. |
| `delegate_to` task uses the wrong variables | Variables in a delegated task still come from the **current** host, not the delegated one. | Read the other host's values with `hostvars[db_host]`. |
| `run_once` task runs on an unexpected host | It runs on the first host in the batch. | Add `delegate_to:` if it must run on a specific host. |
| `ERROR! ... Attempted to read "inventory.yml" as ini` | Normal: Ansible tries each inventory parser in turn. | Only a problem if the YAML parser fails too. Check indentation. |
| Same variable has a different value than expected | Variable precedence: host vars beat group vars, child groups beat parent groups. | `ansible-inventory --host <name>` shows the final values. |
