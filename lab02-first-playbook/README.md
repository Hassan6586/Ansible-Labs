# Lab 02: Writing your first playbook

Ad-hoc commands are great for one-off jobs. For anything you'll repeat, you write a **playbook**: a YAML file
that lists the tasks to run, in order, on a group of hosts.

## 🎯 What you'll learn

- The structure of a playbook: plays, hosts, tasks and modules
- How to use variables and lists in a playbook
- How to run a playbook safely: `--syntax-check`, `--list-tasks`, `--check` and `--diff`
- How to read the **PLAY RECAP** at the end of a run

## 🧠 Key ideas in plain words

| Term | What it means |
| --- | --- |
| **Playbook** | A YAML file with one or more plays. |
| **Play** | "On these hosts, run these tasks." |
| **Task** | One step, which calls one module with some arguments. Every task should have a `name`. |
| **`become: true`** | Run the tasks with sudo (as root). |
| **Check mode (`--check`)** | A dry run: Ansible reports what *would* change without changing anything. |
| **FQCN** | The fully qualified module name, such as `ansible.builtin.apt`. It makes clear exactly which module you mean. |

> 💡 **YAML rules that trip up beginners:** use **spaces, never tabs**; indentation shows structure (2 spaces per
> level here); a list item starts with `- `; a file starts with `---`.

## ✅ Before you start

- Lab 01 completed (Ansible installed)

```bash
cd ~/Ansible-Labs/lab02-first-playbook
```

## 🛠 Step 1: Read your first playbook

Open `hello.yml`:

```yaml
---
- name: My first playbook
  hosts: local            # which inventory group to run on
  gather_facts: true      # collect system facts before the tasks run

  tasks:
    - name: Say hello
      ansible.builtin.debug:
        msg: "Hello from {{ ansible_facts['hostname'] }}, running {{ ansible_facts['distribution'] }} {{ ansible_facts['distribution_version'] }}"

    - name: Create a working folder
      ansible.builtin.file:
        path: /tmp/lab02
        state: directory
        mode: "0755"

    - name: Write a file into it
      ansible.builtin.copy:
        dest: /tmp/lab02/welcome.txt
        content: |
          This file was created by Ansible.
          Run the playbook again and Ansible will report "ok" instead of "changed".
        mode: "0644"
```

- `{{ ... }}` inserts a value. `ansible_facts['hostname']` is a **fact** that Ansible collected about the machine.
- `file` and `copy` describe the end state ("this folder exists", "this file has this content"), not the steps to
  get there.

## 🛠 Step 2: Check, then run it

```bash
ansible-playbook hello.yml --syntax-check
ansible-playbook hello.yml
```

The output ends with a **PLAY RECAP**:

```text
PLAY RECAP *********************************************************
localhost  : ok=4  changed=2  unreachable=0  failed=0  skipped=0 ...
```

| Counter | Meaning |
| --- | --- |
| `ok` | Tasks that ran successfully (including the ones that changed something) |
| `changed` | Tasks that actually changed the machine |
| `failed` / `unreachable` | Problems; these should be 0 |

Now run it **again**. This time `changed=0`, because the folder and file already match what the playbook
describes.

## 🛠 Step 3: A playbook with variables and sudo

Open `install-multiple-packages.yml`. It keeps the package list in a **variable** and installs them all in one task:

```yaml
- name: Install multiple useful packages
  hosts: local
  become: true

  vars:
    packages_to_install: [curl, wget, git, vim, tree, unzip]

  tasks:
    - name: Update the apt package cache (at most once an hour)
      ansible.builtin.apt:
        update_cache: true
        cache_valid_time: 3600

    - name: Install the packages
      ansible.builtin.apt:
        name: "{{ packages_to_install }}"
        state: present
```

Look before you leap:

```bash
# Which tasks will run, and on which hosts?
ansible-playbook install-multiple-packages.yml --list-tasks --list-hosts

# Dry run: what WOULD change? (-K asks for your sudo password)
ansible-playbook install-multiple-packages.yml --check --diff -K
```

Then run it for real, twice:

```bash
ansible-playbook install-multiple-packages.yml -K
ansible-playbook install-multiple-packages.yml -K   # second run: changed=0
```

## 🧪 Try it yourself

1. Add `htop` to `packages_to_install` and run the playbook. Only the install task should report `changed`.
2. Add `-v` to the command and compare the output.
3. Change `state: present` to `state: latest`. What's the difference? (Answer in [interview_qna.md](interview_qna.md).)

## 🔍 Verify

```bash
cat /tmp/lab02/welcome.txt
tree --version && git --version && unzip -v | head -1
```

## 🧹 Clean up

```bash
rm -rf /tmp/lab02
```

The packages are useful, so leave them installed.

➡️ **Next:** [Lab 03: Managing inventory](../lab03-managing-inventory/)
