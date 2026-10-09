# Lab 01: Introduction to Ansible

Install Ansible, connect it to a machine, and run your first commands. Everything in this lab runs on a
single Ubuntu machine, so you don't need a second server.

## 🎯 What you'll learn

- What Ansible is and why DevOps teams use it
- How to install Ansible the right way on Ubuntu
- What an **inventory** and an **ansible.cfg** file are
- How to run **ad-hoc commands** against one or many machines

## 🧠 Key ideas in plain words

| Term | What it means |
| --- | --- |
| **Control node** | The machine where Ansible is installed and where you type commands. |
| **Managed node** | A machine Ansible configures. Ansible connects to it over SSH; nothing needs to be installed on it except Python. |
| **Inventory** | A file listing your managed nodes, sorted into groups such as `webservers` or `databases`. |
| **Module** | A small tool that does one job, like `apt` (install packages) or `copy` (write a file). |
| **Ad-hoc command** | One module run once from the terminal, without writing a playbook. |
| **Agentless** | Ansible doesn't install an agent on your servers. It uses SSH and Python, which are already there. |

## ✅ Before you start

- Ubuntu 22.04 or 24.04 (a VM, WSL2 or a cloud server), with `sudo` access
- Basic terminal skills: `cd`, `ls`, editing a file

Clone this repository once and use it for all 20 labs:

```bash
git clone https://github.com/Hassan6586/Ansible-Labs.git ~/Ansible-Labs
cd ~/Ansible-Labs/lab01-introduction-to-ansible
```

## 🛠 Step 1: Install Ansible

```bash
sudo apt update
sudo apt install -y software-properties-common
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install -y ansible
ansible --version
```

The last command prints something like:

```text
ansible [core 2.x.x]
  config file = None
  python version = 3.12.x
```

> 💡 **Why not `pip3 install ansible`?** On Ubuntu 24.04, `pip3 install` outside a virtual environment fails with
> `error: externally-managed-environment`. The official Ansible PPA above is the simplest way to get a current
> version. (If you prefer pip, use `pipx install --include-deps ansible`.)

## 🛠 Step 2: Let Ansible reach this machine over SSH

Real servers are reached over SSH, so we'll practise that by connecting to our own machine (`127.0.0.1`).

```bash
# Make sure an SSH server is running
sudo apt install -y openssh-server
sudo systemctl enable --now ssh

# Create a key pair just for Ansible (no passphrase, for the lab)
ssh-keygen -t ed25519 -f ~/.ssh/ansible_key -N ""

# Allow that key to log in as you
cat ~/.ssh/ansible_key.pub >> ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

# Test it: this should print your hostname without asking for a password
ssh -i ~/.ssh/ansible_key -o StrictHostKeyChecking=accept-new "$USER@127.0.0.1" hostname
```

## 🛠 Step 3: Understand the inventory and config file

This folder already contains both files. Open them and read the comments.

**`inventory.ini`**: the machines Ansible manages, in groups.

```ini
[local]
localhost ansible_connection=local

[remote]
lab-node ansible_host=127.0.0.1

[remote:vars]
ansible_ssh_private_key_file=~/.ssh/ansible_key

[all:vars]
ansible_python_interpreter=/usr/bin/python3
```

- `localhost` in the `local` group is reached **directly**, without SSH.
- `lab-node` in the `remote` group is reached **over SSH**, like a real server.
- We don't set `ansible_user`, so Ansible logs in as **you**.

**`ansible.cfg`**: settings Ansible uses when you run commands from this folder. It points to `inventory.ini`,
so you don't have to type `-i inventory.ini` every time.

See the inventory the way Ansible sees it:

```bash
ansible-inventory --graph
ansible all --list-hosts
```

Expected:

```text
@all:
  |--@ungrouped:
  |--@local:
  |  |--localhost
  |--@remote:
  |  |--lab-node
```

## 🛠 Step 4: Run ad-hoc commands

The pattern is always: `ansible <which hosts> -m <module> -a "<arguments>"`.

```bash
# 1. Can Ansible reach every host and run Python there?
ansible all -m ping
```

```text
localhost | SUCCESS => ...
    ping: pong
lab-node | SUCCESS => ...
    ping: pong
```

```bash
# 2. Run a shell command everywhere
ansible all -m command -a "uptime"

# 3. Collect facts (system information) about a host
ansible local -m setup -a "filter=ansible_distribution*"

# 4. Write a file on the "remote" host, then read it back
ansible remote -m copy -a "content='Hello from Ansible\n' dest=/tmp/hello.txt"
ansible remote -m command -a "cat /tmp/hello.txt"

# 5. Install a package (needs root, so add --become and type your sudo password)
ansible local -m apt -a "name=tree state=present" --become --ask-become-pass
```

Notice the colors in the output:

- **Green** (`SUCCESS`, `ok`): nothing had to change.
- **Yellow** (`CHANGED`): Ansible changed something.
- **Red** (`FAILED`, `UNREACHABLE`): something went wrong. See [troubleshooting.md](troubleshooting.md).

Run command 4 twice. The first time the file is created (`CHANGED`); the second time Ansible sees it's already
correct and does nothing (`SUCCESS`). That behavior is called **idempotence**, and you'll study it in Lab 07.

## 🔍 Verify

```bash
ansible all -m ping          # both hosts answer "pong"
cat /tmp/hello.txt           # prints "Hello from Ansible"
tree --version               # tree is installed
```

## 🧹 Clean up

```bash
ansible remote -m file -a "path=/tmp/hello.txt state=absent"
```

Keep the SSH key; later labs use it.

## 📚 Files in this lab

| File | Purpose |
| --- | --- |
| `inventory.ini` | The machines and groups |
| `ansible.cfg` | Settings for this folder |
| `commands.sh` | Every command from this README, in order |
| `troubleshooting.md` | Common errors and fixes |
| `interview_qna.md` | Interview questions on this topic |

➡️ **Next:** [Lab 02: Writing your first playbook](../lab02-first-playbook/)
