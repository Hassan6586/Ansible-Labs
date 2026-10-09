# Lab 13: Interview questions

**1. What would you include in a Linux hardening baseline?**
SSH hardening (no root login, key-only auth, low MaxAuthTries), a default-deny firewall, fail2ban, automatic security
updates, minimal packages and services, file permission checks, auditing/logging, and time sync.

**2. How do you change sshd settings with Ansible without risking a broken SSH daemon?**
Use `template` or `lineinfile` with `validate: /usr/sbin/sshd -t -f %s`. If the test fails, the original file is
left untouched.

**3. Why put SSH settings in `/etc/ssh/sshd_config.d/` instead of editing `sshd_config`?**
The main file stays as the vendor shipped it (easier upgrades), and your settings live in one file you fully own.

**4. In which order must you configure ufw on a remote server?**
Allow SSH first, then set default deny, then enable the firewall. Enabling before allowing SSH can cut your
connection.

**5. What does `sshd -T` show?**
The effective configuration after all files are merged: the best source of truth for an audit.

**6. What is fail2ban?**
A service that watches logs for repeated failures (such as SSH logins) and temporarily bans the offending IPs with
firewall rules.

**7. How do you prove a server is compliant?**
Run a read-only audit (Ansible `assert`, or tools like OpenSCAP, Lynis or InSpec) and run it regularly, not just
once.

**8. What are CIS benchmarks?**
Industry-standard security configuration guidelines. There are Ansible roles (for example ansible-lockdown) that
apply them.

**9. How do you keep hardening consistent across hundreds of servers?**
One role in version control, applied by a scheduled job (AWX/AAP, cron, CI) so drift is corrected automatically.

**10. Why use `--check --diff` before running a security playbook?**
To see exactly what will change on a live server before applying it, especially for access-related settings.
