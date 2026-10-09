# Lab 07: Troubleshooting

| Problem | Why it happens | Fix |
| --- | --- | --- |
| A task always shows `changed` | It uses `command`/`shell`, or it always rewrites the file. | Use a dedicated module, or add `creates:`, `removes:` or `changed_when:`. |
| `lineinfile` adds a second line instead of replacing | No `regexp:`, so it only checks for the exact `line`. | Add `regexp: '^key='` to match the existing line. |
| A template task always reports `changed` | The template contains something that changes every run, such as a timestamp. | Remove the timestamp, or use `ansible_managed` without dates. |
| `apt` shows `changed` every run | `update_cache: true` without `cache_valid_time`, or `state: latest`. | Add `cache_valid_time: 3600`; use `state: present`. |
| `--check` says `changed` but the real run doesn't (or the reverse) | Some tasks depend on earlier ones that didn't really run in check mode. | Expected for `command`/`shell`. Mark safe read-only tasks with `check_mode: false`. |
| `[WARNING]: Consider using the file module` | `ansible-lint`/Ansible suggests a module instead of a command. | Use the suggested module. |
