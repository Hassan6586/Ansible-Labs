# Lab 16: Troubleshooting

| Problem | Why it happens | Fix |
| --- | --- | --- |
| `'item' is undefined` | `item` is used outside a task that has `loop:`, or the loop line is indented wrong. | `loop:` must be at the same level as the module name, not inside the module's arguments. |
| `'dict object' has no attribute 'name'` | The loop list is a list of plain strings, not dictionaries. | Check the data with `debug: var=app_users`. |
| `Invalid data passed to 'loop', it requires a list` | You passed a dictionary to `loop`. | Use `loop: "{{ my_dict \| dict2items }}"`. |
| Output is huge for every item | Ansible prints the whole item. | Add `loop_control: { label: "{{ item.name }}" }`. |
| `The loop variable 'item' is already in use` | An included file loops too, and both use `item`. | Set `loop_control: { loop_var: env_name }` on the outer loop. |
| `--tags include` runs the include but none of its tasks | Tags on `include_tasks` don't flow into the included file. | Tag the tasks inside the file too, or use `apply: { tags: [...] }`. |
| `until` gives up right away | `retries` is missing (default 3) or the condition checks the wrong field. | Set `retries` and `delay`, and print the registered result to check the field name. |
| User task fails with "permission denied" | Creating users needs root. | Keep `become: true`, and run with `-K` if sudo needs a password. |
| `usermod: group 'sudo' does not exist` | RHEL-family systems use `wheel`, not `sudo`. | Use `groups: [wheel]` on Rocky/Alma/Fedora. |
