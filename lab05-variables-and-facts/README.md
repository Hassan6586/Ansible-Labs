# Lab 05: Variables and facts

Hard-coded values make playbooks rigid. **Variables** let one playbook work for many environments, and **facts**
(information Ansible discovers about each machine) let a playbook make decisions, such as "only warn if RAM is
low" or "use apt on Ubuntu, dnf on Red Hat".

## 🎯 What you'll learn

- Where variables can be defined, and which one wins when the same name is set twice
- Strings, lists and dictionaries, and how to read them
- Filters such as `upper`, `join` and `default`
- `register` and `set_fact` to create variables while a play runs
- Facts (`ansible_facts`) and `when:` conditions

## 🧠 Key ideas in plain words

| Term | What it means |
| --- | --- |
| **Variable** | A named value, used as `{{ name }}` |
| **Fact** | A variable Ansible discovers about a host (OS, RAM, IPs), stored in `ansible_facts` |
| **Filter** | Transforms a value: `{{ name \| upper }}` |
| **`register`** | Saves a task's result (output, exit code) into a variable |
| **`set_fact`** | Creates or changes a variable while the play runs |
| **`when:`** | Runs a task only if a condition is true; otherwise it's **skipped** |

## ✅ Before you start

No sudo needed in this lab.

```bash
cd ~/Ansible-Labs/lab05-variables-and-facts
```

## 🛠 Step 1: Look at facts

```bash
ansible local -m setup | less                         # everything (press q to quit)
ansible local -m setup -a "filter=ansible_memtotal_mb"
ansible local -m setup -a "filter=ansible_default_ipv4"
```

In a playbook, read facts from `ansible_facts`, without the `ansible_` prefix:
`ansible_facts['memtotal_mb']`, `ansible_facts['os_family']`, `ansible_facts['hostname']`.

## 🛠 Step 2: Where variables come from

`variables.yml` uses three sources:

```yaml
- name: Where variables come from
  hosts: local
  gather_facts: false

  vars:                       # 1. play variables
    greeting: "Hello from the play"
    replicas: 2

  vars_files:                 # 2. variables from a file
    - vars/app.yml
```

…and `group_vars/local.yml` (3. group variables) also sets `greeting`. Run it:

```bash
ansible-playbook variables.yml
```

```text
TASK [A simple variable]
    msg: inventory-service listens on port 8080
TASK [A list (use an index, starting at 0)]
    msg: 'First feature: login; all features: login, reports, export'
TASK [A dictionary (use dot or bracket notation)]
    msg: 'Owner: Hassan from the Platform team'
TASK [Which greeting wins? (play vars beat group_vars; -e beats everything)]
    greeting: Hello from the play
TASK [Filters change values]
    msg:
    - 'Upper case: INVENTORY-SERVICE'
    - 'Default for a missing variable: localhost'
    - Replicas x 3 = 6
TASK [Use the registered result]
    msg: Today is 2026-10-09 (exit code 0)
TASK [Show it]
    release_tag: inventory-service-2026-10-09
```

Now override `greeting` from the command line. **Extra vars (`-e`) always win:**

```bash
ansible-playbook variables.yml -e greeting="Hello from the command line"
```

### Which value wins? (simplified)

From **lowest** to **highest** priority:

```text
role defaults → inventory group_vars → playbook group_vars → host_vars
→ facts → play vars → vars_files → registered vars / set_fact → extra vars (-e)
```

You don't need to memorise the full list of 22 levels. Remember: **role defaults lose, `-e` wins, and
host-specific beats group-wide.**

## 🛠 Step 3: Register and set_fact

```yaml
- name: Save a command's result with register
  ansible.builtin.command: date +%Y-%m-%d
  register: today
  changed_when: false       # reading the date changes nothing, so don't report "changed"

- name: Use the registered result
  ansible.builtin.debug:
    msg: "Today is {{ today.stdout }} (exit code {{ today.rc }})"

- name: Create a new variable while the play runs
  ansible.builtin.set_fact:
    release_tag: "{{ app_name }}-{{ today.stdout }}"
```

A registered variable holds the whole result: `stdout`, `stderr`, `rc` (exit code), `changed` and more. Use
`ansible.builtin.debug: var=today` to see all of it.

## 🛠 Step 4: Let facts drive decisions

`fact-deployment.yml` warns only when RAM is low and picks tasks by OS family:

```yaml
- name: Warn when RAM is low
  ansible.builtin.debug:
    msg: "WARNING: only {{ ansible_facts['memtotal_mb'] }} MB of RAM (below {{ min_ram_mb }} MB)"
  when: ansible_facts['memtotal_mb'] < min_ram_mb

- name: Debian/Ubuntu-only task
  ansible.builtin.debug:
    msg: "This is a Debian-family system, so we would use apt here."
  when: ansible_facts['os_family'] == "Debian"
```

```bash
ansible-playbook fact-deployment.yml
```

On Ubuntu, the RedHat task shows `skipping`, and so does whichever RAM task doesn't apply. Force the warning by
raising the limit:

```bash
ansible-playbook fact-deployment.yml -e min_ram_mb=999999
cat /tmp/lab05-system-report.txt
```

> 💡 Inside `when:`, don't use `{{ }}`. Write `when: app_port > 1024`, not `when: "{{ app_port }} > 1024"`.

## 🧪 Try it yourself

1. Add `app_version: "1.4.2"` to `vars/app.yml` and print it.
2. Add a task that runs only when the machine has more than 2 CPUs.
3. Register the output of `uname -r` and print only the first line.

## 🔍 Verify

`/tmp/lab05-system-report.txt` exists and shows your OS, CPUs and RAM.

## 🧹 Clean up

```bash
rm -f /tmp/lab05-system-report.txt
```

➡️ **Next:** [Lab 06: Ansible Vault](../lab06-ansible-vault/)
