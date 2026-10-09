# Lab 01: Interview questions

**1. What is Ansible?**
An open-source automation tool for configuration management, application deployment and orchestration. You
describe the state you want in YAML and Ansible makes the machines match it.

**2. What does "agentless" mean, and why does it matter?**
Ansible doesn't need any software installed on managed nodes; it connects over SSH (or WinRM for Windows) and runs
small Python programs. There are no agents to install, update or secure.

**3. What is the difference between the control node and a managed node?**
The control node runs Ansible. Managed nodes are the machines it configures. Ansible can't run on Windows as a
control node (use WSL), but it can manage Windows hosts.

**4. What is an inventory?**
A list of managed hosts, grouped (for example `webservers`, `databases`), with optional variables per host or
group. It can be a static INI/YAML file or generated dynamically from a cloud provider.

**5. What is an ad-hoc command? When would you use one?**
A single module run from the command line, such as `ansible all -m ping`. Good for quick checks or one-off
tasks; anything you'll repeat belongs in a playbook.

**6. What does the `ping` module actually check?**
That Ansible can log in to the host and run Python there. It is not an ICMP ping.

**7. What is the difference between the `command` and `shell` modules?**
`command` runs a program directly without a shell, so pipes, redirects and variables like `$HOME` don't work.
`shell` runs through `/bin/sh`, so they do. Prefer `command` (safer) unless you need shell features.

**8. What do `--become` and `--ask-become-pass` do?**
`--become` runs the task with elevated privileges (sudo by default). `--ask-become-pass` (`-K`) prompts for the
sudo password.

**9. Where does Ansible look for `ansible.cfg`?**
In order: the `ANSIBLE_CONFIG` environment variable, `./ansible.cfg` in the current folder, `~/.ansible.cfg`,
then `/etc/ansible/ansible.cfg`. The first one found wins.

**10. What is `host_key_checking`, and should you disable it?**
It makes Ansible refuse hosts whose SSH key it hasn't seen. Disabling it is convenient in throwaway labs but
removes protection against man-in-the-middle attacks, so keep it on in production.
