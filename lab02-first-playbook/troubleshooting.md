# Lab 02: Troubleshooting

| Problem | Why it happens | Fix |
| --- | --- | --- |
| `ERROR! ... found character that cannot start any token` | A **tab** character in the YAML. | Replace tabs with spaces. In vim: `:set expandtab` then `:retab`. |
| `mapping values are not allowed in this context` | Bad indentation or a missing space after `:`. | Every `key: value` needs a space after the colon; line up items at the same level. |
| `Missing sudo password` | The playbook has `become: true` but you didn't pass `-K`. | Run with `-K` (`--ask-become-pass`). |
| `Could not get lock /var/lib/dpkg/lock-frontend` | Another apt process (often automatic updates) is running. | Wait a minute and retry, or check with `ps aux \| grep apt`. |
| `No package matching 'xyz' is available` | Typo in the package name, or the cache is old. | Check the name with `apt-cache search xyz`. |
| `template error while templating string` | A `{{ }}` expression is broken, or a value starting with `{{` isn't in quotes. | Quote any value that starts with `{{`, for example `msg: "{{ var }}"`. |
| `[WARNING]: Could not match supplied host pattern` | `hosts:` names a group that isn't in the inventory. | Check `inventory.ini`; group names are case-sensitive. |
