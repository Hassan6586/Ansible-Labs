# Lab 13: Enforcing security with Ansible

A fresh server is not a safe server. This lab applies a **hardening baseline**, the first thing a DevOps
engineer does to any new Linux machine, and then **audits** it, so the same security settings are applied the
same way everywhere.

> ⚠️ **Use a VM where you have console access** (VirtualBox, a cloud VM with a serial console). Mistakes in SSH or
> firewall settings can lock you out of a remote server. The playbook is written to prevent that, but practise
> safely. Keep one SSH session open while you test in another.

## 🎯 What you'll learn

- SSH hardening with a validated drop-in config file
- A default-deny firewall with `ufw`, allowing SSH **first**
- Blocking brute-force attacks with `fail2ban`
- Automatic security updates
- Writing an **audit** playbook with `assert`
- Rolling changes back

## 🧠 Key ideas in plain words

| Setting | Why it matters |
| --- | --- |
| `PermitRootLogin no` | Attackers always try `root`. Log in as a normal user and use sudo. |
| `MaxAuthTries 3` | Fewer password guesses per connection. |
| `PasswordAuthentication no` | Only SSH keys can log in, which stops password guessing completely. (Optional here.) |
| `ufw default deny incoming` | Every port is closed unless you open it. |
| `fail2ban` | Bans an IP for an hour after 5 failed logins in 10 minutes. |
| `unattended-upgrades` | Installs security patches automatically every day. |
| `validate:` | Ansible tests the new file **before** replacing the old one, so a typo can't break SSH. |

## ✅ Before you start

- Key-based SSH login working (Lab 01, Step 2)
- `community.general` collection (included with the `ansible` package)

```bash
cd ~/Ansible-Labs/lab13-security-hardening
```

## 🛠 Step 1: Read the playbook

**SSH**: a drop-in file instead of editing `sshd_config` line by line:

```yaml
- name: Write SSH hardening settings (validated with sshd -t before saving)
  ansible.builtin.template:
    src: 01-hardening.conf.j2
    dest: /etc/ssh/sshd_config.d/01-hardening.conf
    mode: "0644"
    validate: /usr/sbin/sshd -t -f %s
  notify: Restart SSH
```

> 💡 sshd uses the **first** value it finds and reads `sshd_config.d/*.conf` in name order. Cloud images often
> ship `50-cloud-init.conf` with `PasswordAuthentication yes`, so our file is named `01-...` to be read first.

**Firewall**: the order matters:

```yaml
- name: Allow SSH through the firewall FIRST (so we can't lock ourselves out)
  community.general.ufw:
    rule: allow
    name: OpenSSH

- name: Deny all other incoming traffic by default
  community.general.ufw:
    default: deny
    direction: incoming

- name: Turn the firewall on
  community.general.ufw:
    state: enabled
```

**Passwords**: `hardening_ssh_disable_passwords` is `false` by default. The template only adds
`PasswordAuthentication no` when you set it to `true`.

## 🛠 Step 2: Preview, then apply

```bash
ansible-playbook ssh-hardening.yml --check --diff -K
ansible-playbook ssh-hardening.yml -K
ansible-playbook ssh-hardening.yml -K      # second run: changed=0
```

In another terminal, make sure you can still log in:

```bash
ssh -i ~/.ssh/ansible_key "$USER@127.0.0.1" hostname
```

## 🛠 Step 3: Audit

`audit.yml` only **reads** the system and fails if anything is off:

```yaml
- name: Check the results
  ansible.builtin.assert:
    that:
      - "'permitrootlogin no' in sshd_effective.stdout"
      - "'maxauthtries 3' in sshd_effective.stdout"
      - "'Status: active' in ufw_status.stdout"
      - "'Default: deny (incoming)' in ufw_status.stdout"
      - f2b.rc == 0
```

```bash
ansible-playbook audit.yml -K
```

```text
TASK [Check the results]
    msg: All hardening checks passed ✅
```

`sshd -T` prints the settings sshd is **actually** using, after all files are merged, which is more trustworthy
than reading config files.

## 🛠 Step 4 (optional): Keys only

Only after `ssh -i ~/.ssh/ansible_key ...` works:

```bash
ansible-playbook ssh-hardening.yml -K -e hardening_ssh_disable_passwords=true
sudo sshd -T | grep passwordauthentication       # passwordauthentication no
```

## 🧪 Try it yourself

1. Open port 8088 for Lab 12 with a `community.general.ufw` task (`rule: allow`, `port: "8088"`, `proto: tcp`).
2. Add `AllowUsers {{ lookup('env', 'USER') }}` to the SSH template.
3. Add an audit check that `/etc/shadow` has mode `0640`, using `ansible.builtin.stat`.

## 🔍 Verify

```bash
sudo sshd -T | grep -E "permitrootlogin|maxauthtries|x11forwarding"
sudo ufw status verbose
sudo fail2ban-client status sshd
```

## 🧹 Clean up

On a throwaway VM, keep the hardening; it's good practice. On your own laptop or WSL, roll it back:

```bash
ansible-playbook rollback.yml -K
```

➡️ **Next:** [Lab 14: Error handling and blocks](../lab14-error-handling-and-blocks/)
