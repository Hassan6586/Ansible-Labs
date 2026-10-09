# Lab 04: Troubleshooting

| Problem | Why it happens | Fix |
| --- | --- | --- |
| `the role 'webserver' was not found` | Ansible can't see the `roles/` folder. | Run from this lab's folder (where `ansible.cfg` sets `roles_path = ./roles`), or put `roles/` next to the playbook. |
| `Could not find or access 'index.html.j2'` | The template isn't in the role's `templates/` folder, or the name is misspelt. | Check `roles/webserver/templates/index.html.j2`. |
| The handler never runs | The task didn't report `changed`, or the `notify` name doesn't match the handler `name` exactly. | Names are case-sensitive. Force a change with `-e webserver_owner=test`. |
| The handler didn't run because a later task failed | Handlers run at the end of the play, which a failure stops early. | Fix the failure, or use `--force-handlers` or `meta: flush_handlers`. |
| `Address already in use` / Apache won't start | Another web server (nginx) is already on port 80. | `sudo ss -ltnp \| grep :80` to find it; stop it or change the port. |
| `curl: (7) Failed to connect to localhost port 80` | Apache isn't running, or you're testing from outside a VM. | `systemctl status apache2`. From your laptop, use the VM's IP and check its firewall. |
| `'ansible_facts' is undefined` in the template | The play has `gather_facts: false`. | Leave fact gathering on (the default) when templates use facts. |
