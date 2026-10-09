# Lab 16: Loops and advanced playbooks

Creating 3 folders with 3 copies of the same task works. Creating 50 doesn't. **Loops** let one task handle
a whole list, and a few extra tools (`loop_control`, `until`, `include_tasks`, tags) make big playbooks easy to
read and to run in parts.

## 🎯 What you'll learn

- `loop` over a list, a list of dictionaries, and a dictionary (`dict2items`)
- `loop_control`: `label`, `index_var`, `extended`, `loop_var`
- Nested loops with `product`, and loops with `when`
- `register` on a loop, and `until` / `retries`
- Repeating a group of tasks with `include_tasks`
- Running only part of a playbook with **tags**

## 🧠 Key ideas in plain words

| Thing | What it does |
| --- | --- |
| `loop:` | Run the task once per item; the current item is `item` |
| `with_items:` | The old way to loop. It still works, but use `loop` in new code |
| `dict2items` | Turns `{a: 1}` into `[{key: a, value: 1}]` so you can loop over it |
| `loop_control.label` | What to print for each item (keeps the output short) |
| `loop_control.loop_var` | Rename `item`, needed when loops are nested inside included files |
| `until` + `retries` | Repeat **one** task until a condition is true |
| `include_tasks` | Pull in a file of tasks; with `loop`, run the whole file per item |
| `tags` | Labels on tasks so you can run (`--tags`) or skip (`--skip-tags`) them |

## ✅ Before you start

Task 2 creates real Linux users, so it uses `become: true`. If your user needs a password for sudo, add
`-K` (`--ask-become-pass`) to the commands below.

```bash
cd ~/Ansible-Labs/lab16-loops-and-advanced-playbooks
```

## 🛠 Step 1: Look at the loops

`loops.yml` has one example per pattern. The interesting ones:

```yaml
- name: 2. Loop over a list of dictionaries (one user per item)
  ansible.builtin.user:
    name: "{{ item.name }}"
    shell: "{{ item.shell }}"
    groups: "{{ item.groups }}"
    append: true
  loop: "{{ app_users }}"
  loop_control:
    label: "{{ item.name }}"      # print only the name, not the whole dict
  become: true

- name: 3. Loop over a dictionary with dict2items
  ansible.builtin.lineinfile:
    path: "{{ base_dir }}/config/app.ini"
    regexp: "^{{ item.key }}="
    line: "{{ item.key }}={{ item.value }}"
    create: true
  loop: "{{ app_settings | dict2items }}"

- name: 5. Nested loop (every environment x every folder)
  ansible.builtin.file:
    path: "{{ base_dir }}/envs/{{ item.0 }}/{{ item.1 }}"
    state: directory
  loop: "{{ environments | product(app_folders) | list }}"

- name: 9. Repeat a whole group of tasks for each item (include_tasks)
  ansible.builtin.include_tasks: tasks/setup_environment.yml
  loop: "{{ environments }}"
  loop_control:
    loop_var: env_name
```

> 💡 **Upgrading old playbooks:** `with_items: [...]` becomes `loop: [...]`, and
> `with_dict: "{{ d }}"` becomes `loop: "{{ d | dict2items }}"`.

## 🛠 Step 2: Run it

```bash
ansible-playbook loops.yml
```

```text
TASK [1. Loop over a simple list]
changed: [localhost] => (item=logs)
changed: [localhost] => (item=data)
changed: [localhost] => (item=config)

TASK [2. Loop over a list of dictionaries (one user per item)]
changed: [localhost] => (item=appuser1)
changed: [localhost] => (item=appuser2)
changed: [localhost] => (item=deployer)

TASK [4. Know where you are in the loop (index_var, extended)]
    msg: 'Item 1 of 3: logs'
    msg: 'Item 2 of 3: data'
    msg: 'Item 3 of 3: config (last one)'

TASK [5. Nested loop (every environment x every folder)]
changed: [localhost] => (item=dev/logs)
...
changed: [localhost] => (item=staging/config)

TASK [6. Loop with a condition (skip some items)]
skipping: [localhost] => (item=appuser1)
skipping: [localhost] => (item=appuser2)
ok: [localhost] => (item=deployer) =>
    msg: deployer can use sudo

TASK [8. Retry until a condition is true (until)]
FAILED - RETRYING: [localhost]: 8. Retry until a condition is true (until) (4 retries left).
FAILED - RETRYING: [localhost]: 8. Retry until a condition is true (until) (3 retries left).
changed: [localhost]

TASK [Show how many attempts it took]
    msg: Succeeded after 3 attempts

TASK [9. Repeat a whole group of tasks for each item (include_tasks)]
included: .../tasks/setup_environment.yml for localhost => (item=dev)
included: .../tasks/setup_environment.yml for localhost => (item=staging)

PLAY RECAP
localhost : ok=19  changed=7  unreachable=0  failed=0  skipped=0
```

The `FAILED - RETRYING` lines are normal: the task is designed to "succeed" on its third attempt, like a
service that needs a few seconds to start.

Run it again. Only the counter tasks change; everything else is already done (`ok`).

## 🛠 Step 3: Run only part of the playbook with tags

See the tasks and tags without running anything:

```bash
ansible-playbook loops.yml --list-tasks
```

```text
  play #1 (local): Loop-driven provisioning	TAGS: []
    tasks:
      1. Loop over a simple list	TAGS: [basics]
      2. Loop over a list of dictionaries (one user per item)	TAGS: [users]
      3. Loop over a dictionary with dict2items	TAGS: [dicts]
      ...
      9. Repeat a whole group of tasks for each item (include_tasks)	TAGS: [include]
```

```bash
ansible-playbook loops.yml --tags dicts            # only task 3
ansible-playbook loops.yml --tags basics,nested    # tasks 1, 4, 5, 7
ansible-playbook loops.yml --skip-tags users       # everything except the user tasks
```

> 💡 Tags on `include_tasks` only select the include itself. The tasks inside the file need the same tag too,
> which is why every task in `tasks/setup_environment.yml` has `tags: [include]`.

## 🧠 `include_tasks` vs `import_tasks`

| | `include_tasks` (dynamic) | `import_tasks` (static) |
| --- | --- | --- |
| When it's read | While the play runs | Before the play starts |
| Works with `loop` | ✅ Yes | ❌ No |
| Shows up in `--list-tasks` | Only the include line | Every task inside |
| Tags / `when` | Apply to the include line | Copied to every task inside |

Rule of thumb: use `import_tasks` for fixed structure, `include_tasks` when you need a loop or a file name
decided at runtime.

## 🧪 Try it yourself

1. Add a `production` environment to `environments`. How many folders does task 5 create now?
2. Add a fourth user with `groups: [sudo]` and see which users task 6 prints.
3. Change task 8 to `until: counter.stdout | int >= 10`. What happens after 5 retries?
4. Rewrite task 1 with the old `with_items:` syntax. Does the output change?
5. Add `loop_control: { pause: 1 }` to task 1 and watch it slow down.

## 🔍 Verify

```bash
tree /tmp/lab16                 # or: find /tmp/lab16
cat /tmp/lab16/config/app.ini   # max_connections=100, timeout_seconds=30, cache_enabled=True
cat /tmp/lab16/envs/dev/settings.env
id deployer                     # ... groups=...,27(sudo)
```

## 🧹 Clean up

Removes the three users and `/tmp/lab16`:

```bash
ansible-playbook cleanup.yml
```

➡️ **Next:** [Lab 17: AWX (Automation Controller)](../lab17-awx-automation-controller/)
