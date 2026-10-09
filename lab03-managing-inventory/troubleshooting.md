# Lab 03: Troubleshooting

| Problem | Why it happens | Fix |
| --- | --- | --- |
| Variables from `group_vars/` are missing | The folder isn't next to the inventory file (or the playbook). | Move `group_vars/` and `host_vars/` beside `hosts.yml`, or beside your playbook. |
| `[WARNING]: Unable to parse ... as an inventory source` | YAML indentation error, or the wrong file path. | Check the path, then validate with `ansible-inventory -i <file> --list`. |
| `Permission denied` when using `dynamic_inventory.py` | The script isn't executable. | `chmod +x inventories/dynamic/dynamic_inventory.py` |
| Script inventory shows nothing | The script prints something other than valid JSON. | Run it yourself with `--list` and paste the output into a JSON validator. |
| `event not found` when using `!` in a pattern | Bash treats `!` as history expansion. | Wrap the pattern in **single** quotes: `'production:!databases'` |
| A host appears in `ungrouped` | It's listed directly under `all` without a group. | Put it under a group's `hosts:` section. |
| File named `webservers.yaml` is ignored | Typo in the group name, not the extension. | `.yml`, `.yaml`, `.json` and no extension all work; the **name** must match the group exactly. |
