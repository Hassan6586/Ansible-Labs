# Lab 13: Troubleshooting

| Problem | Why it happens | Fix |
| --- | --- | --- |
| `failed to validate` at the SSH task | The rendered file has an error, so `sshd -t` rejected it. Nothing was replaced. | Read the message, fix `templates/01-hardening.conf.j2`, run again. |
| Locked out of a remote server | Passwords disabled before key login worked, or SSH blocked by the firewall. | Use the cloud provider's console, run `rollback.yml` (or `sudo ufw disable`, then delete the drop-in file). |
| `ERROR: Couldn't determine iptables version` / ufw fails | Running inside a container or WSL1 without firewall support. | Use a full VM. On WSL2, ufw usually works; Docker containers don't support it. |
| Settings don't take effect | Another file sets them earlier (for example `50-cloud-init.conf`). | `sudo sshd -T` shows the effective value; make sure our file is named `01-...`. |
| `Unable to find service ssh` | Older systems call it `sshd`. | Change the handler's service name to `sshd`. |
| `fail2ban-client: Failed to access socket path` | fail2ban isn't running. | `sudo systemctl status fail2ban`; check `/etc/fail2ban/jail.local` syntax. |
| You banned yourself | Too many failed logins from your IP. | `sudo fail2ban-client set sshd unbanip <your-ip>` |
