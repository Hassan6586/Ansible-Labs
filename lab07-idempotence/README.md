# Lab 07: Idempotence

**Idempotent** means "running it once or a hundred times gives the same result". It's the most important idea in
configuration management: you can run a playbook again at any time to fix drift, and it changes only what's wrong.

## 🎯 What you'll learn

- Why `shell` and `command` tasks break idempotence, and how to fix them
- Idempotent modules: `file`, `lineinfile`, `copy`, `template`, `apt`, `service`
- `creates:` and `changed_when:` for commands that must run
- How to **prove** a playbook is idempotent, and how Ansible repairs **drift**

## 🧠 Key ideas in plain words

| Imperative (steps) | Declarative (end state) |
| --- | --- |
| "Append this line to the file" | "This line must be in the file" |
| "Run `mkdir`" | "This folder must exist" |
| "Restart the service" | "The service must be running" |

Ansible modules are declarative: they first **check** the current state and only **act** if it differs.
`command` and `shell` can't know what your command does, so they always report `changed`.

## ✅ Before you start

No sudo needed.

```bash
cd ~/Ansible-Labs/lab07-idempotence
```

## 🛠 Step 1: See the problem

`not_idempotent.yml` uses a shell redirect and `mkdir`:

```yaml
- name: Append a line with a shell redirect
  ansible.builtin.shell: echo "app_mode=debug" >> /tmp/lab07_bad.conf

- name: Create a folder with a command
  ansible.builtin.command: mkdir -p /tmp/lab07_bad_dir
```

Run it three times:

```bash
ansible-playbook not_idempotent.yml
ansible-playbook not_idempotent.yml
ansible-playbook not_idempotent.yml
cat /tmp/lab07_bad.conf
```

```text
localhost : ok=2  changed=2 ...      ← every single run reports changes
app_mode=debug
app_mode=debug
app_mode=debug                       ← the line is duplicated each time
```

> The `# noqa` comments in that file tell `ansible-lint` "yes, this is wrong on purpose".

## 🛠 Step 2: The idempotent version

`idempotent_core.yml`:

```yaml
- name: Ensure the folder exists
  ansible.builtin.file:
    path: /tmp/lab07_good_dir
    state: directory
    mode: "0755"

- name: Ensure the config line is present exactly once
  ansible.builtin.lineinfile:
    path: /tmp/lab07_good.conf
    line: app_mode=debug
    create: true
    mode: "0644"

- name: Ensure a setting has the right value (replaces it if it differs)
  ansible.builtin.lineinfile:
    path: /tmp/lab07_good.conf
    regexp: '^log_level='
    line: log_level=info

- name: Run a command only if its result doesn't exist yet
  ansible.builtin.command:
    cmd: tar -czf /tmp/lab07_backup.tar.gz -C /tmp lab07_good.conf
    creates: /tmp/lab07_backup.tar.gz

- name: Read-only command that never changes anything
  ansible.builtin.command: cat /tmp/lab07_good.conf
  register: conf
  changed_when: false
```

Two tools make commands safe:

- **`creates: PATH`** skips the command if that file already exists (`removes:` is the opposite).
- **`changed_when: false`** tells Ansible a read-only command never changes anything.

```bash
ansible-playbook idempotent_core.yml
ansible-playbook idempotent_core.yml
```

```text
localhost : ok=6  changed=4 ...      ← first run: work was needed
localhost : ok=6  changed=0 ...      ← second run: nothing to do ✅
```

## 🛠 Step 3: Prove it automatically

Teams check idempotence in CI by running a playbook twice and failing if the second run changes anything:

```bash
ansible-playbook idempotent_core.yml | tee /tmp/lab07_run.log
grep -q "changed=0" /tmp/lab07_run.log && echo "IDEMPOTENT ✅" || echo "NOT IDEMPOTENT ❌"
```

(Molecule, the role-testing tool, does exactly this in its "idempotence" step.)

## 🛠 Step 4: Repair drift

Someone edits the server by hand:

```bash
sed -i 's/log_level=info/log_level=trace/' /tmp/lab07_good.conf
```

Ask Ansible what it would fix, then fix it:

```bash
ansible-playbook idempotent_core.yml --check --diff
```

```diff
-log_level=trace
+log_level=info
```

```bash
ansible-playbook idempotent_core.yml      # changed=1: only the drifted line is fixed
```

## 🧪 Try it yourself

1. Rewrite `not_idempotent.yml` using `lineinfile` and `file` so the second run reports `changed=0`.
2. Add a task with `ansible.builtin.command: touch /tmp/lab07_flag` and make it idempotent with `creates:`.

## 🔍 Verify

The second run of `idempotent_core.yml` shows `changed=0`, and `/tmp/lab07_good.conf` contains `app_mode=debug`
exactly once.

## 🧹 Clean up

```bash
rm -rf /tmp/lab07_bad.conf /tmp/lab07_bad_dir /tmp/lab07_good.conf /tmp/lab07_good_dir /tmp/lab07_backup.tar.gz /tmp/lab07_run.log
```

➡️ **Next:** [Lab 08: Docker with Ansible](../lab08-docker-with-ansible/)
