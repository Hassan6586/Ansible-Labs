# Lab 14: Error handling and blocks

By default, when a task fails, Ansible stops working on that host. That's safe, but sometimes you want more
control: **roll back** a failed deployment, **retry** a flaky check, **ignore** a harmless error, or decide
yourself what "failed" means.

## 🎯 What you'll learn

- `block` / `rescue` / `always`, Ansible's try / except / finally
- Automatic rollback when a health check fails
- `ansible_failed_task` to report what broke
- `assert` to validate input, `ignore_errors`, `failed_when`, `changed_when`
- `retries` / `until` / `delay` for things that need time
- Why `-e flag=false` needs the `| bool` filter

## 🧠 Key ideas in plain words

| Keyword | What it does |
| --- | --- |
| `block:` | Groups tasks so they can share error handling |
| `rescue:` | Runs only if a task in the block failed (like `except`) |
| `always:` | Runs no matter what (like `finally`) |
| `ignore_errors: true` | Mark the failure as "ignored" and carry on |
| `failed_when:` | Your own rule for failure, such as "disk over 90%" |
| `retries` + `until` + `delay` | Try again up to N times, waiting between tries |
| `assert` | Fail early with a clear message if a condition is false |

## ✅ Before you start

No sudo needed.

```bash
cd ~/Ansible-Labs/lab14-error-handling-and-blocks
```

## 🛠 Step 1: A deployment that rolls itself back

`resilient-deploy.yml` (main part):

```yaml
- name: Deploy, and roll back if anything fails
  block:
    - name: Back up the current version
      ansible.builtin.copy:
        src: "{{ app_dir }}/version.txt"
        dest: "{{ app_dir }}/version.txt.bak"
        remote_src: true

    - name: Write the new version
      ansible.builtin.copy:
        dest: "{{ app_dir }}/version.txt"
        content: "version={{ new_version }}\n"

    - name: Run the post-deploy health check
      ansible.builtin.command: "{{ '/bin/false' if simulate_failure | bool else '/bin/true' }}"

  rescue:
    - name: Explain what went wrong
      ansible.builtin.debug:
        msg: "Task '{{ ansible_failed_task.name }}' failed, so we roll back."
    - name: Restore the previous version
      ansible.builtin.copy:
        src: "{{ app_dir }}/version.txt.bak"
        dest: "{{ app_dir }}/version.txt"
        remote_src: true

  always:
    - name: Read the live version (runs whether the block worked or not)
      ansible.builtin.command: cat {{ app_dir }}/version.txt
      register: live
```

The "health check" fails on purpose (`/bin/false`) so you can watch the rollback:

```bash
ansible-playbook resilient-deploy.yml
```

```text
TASK [Run the post-deploy health check]
fatal: [localhost]: FAILED! => ...
TASK [Explain what went wrong]
    msg: Task 'Run the post-deploy health check' failed, so we roll back.
TASK [Restore the previous version]
changed: [localhost]
TASK [Report it]
    msg: 'Deployment attempt finished. Live: version=1.0'

PLAY RECAP
localhost : ok=8  changed=5  unreachable=0  failed=0  skipped=0  rescued=1  ignored=0
```

Notice `failed=0` and `rescued=1`: the failure was handled, so the play counts as a success.

Now let the health check pass:

```bash
ansible-playbook resilient-deploy.yml -e simulate_failure=false
```

```text
    msg: 'Deployment attempt finished. Live: version=2.0'
```

> 💡 **Why `simulate_failure | bool`?** Values passed with `-e key=value` arrive as **text**. The text `"false"`
> isn't empty, so Jinja treats it as true. The `bool` filter converts `"false"`, `"no"` and `"0"` into a real
> `false`.

## 🛠 Step 2: The rest of the toolbox

`error-controls.yml` shows one tool per task:

```yaml
- name: 1. Validate inputs before doing anything (assert)
  ansible.builtin.assert:
    that:
      - disk_usage_limit | int > 0
      - disk_usage_limit | int <= 100

- name: 2. Keep going even if this fails (ignore_errors)
  ansible.builtin.command: ls /path/that/does/not/exist
  ignore_errors: true

- name: 3. Decide yourself what counts as failure (failed_when)
  ansible.builtin.command: df --output=pcent /
  register: disk
  failed_when: (disk.stdout_lines[-1] | trim | replace('%', '') | int) > disk_usage_limit

- name: 4. grep returns 1 when nothing matches, which is fine for us
  ansible.builtin.command: grep -c "no-such-user" /etc/passwd
  register: grep_result
  failed_when: grep_result.rc not in [0, 1]

- name: 5. Retry until something works (retries / until)
  ansible.builtin.uri:
    url: "http://127.0.0.1:{{ service_port }}/health"
  register: health
  retries: 3
  delay: 2
  until: health.status == 200
```

```bash
ansible-playbook error-controls.yml
```

```text
    msg: Inputs look good
    msg: The ls failed with rc=2, but the play carried on.
    msg: Root disk is 34% full (limit 90%)
FAILED - RETRYING: [localhost]: 5. Retry until something works (retries / until) (2 retries left).
FAILED - RETRYING: [localhost]: 5. Retry until something works (retries / until) (1 retries left).
FAILED - RETRYING: [localhost]: 5. Retry until something works (retries / until) (0 retries left).
    msg: Gave up after 3 attempts (nothing listens on port 8099)
PLAY RECAP
localhost : ok=8 ... failed=0 ... ignored=2
```

Now break the rules on purpose:

```bash
ansible-playbook error-controls.yml -e disk_usage_limit=150   # assert stops the play with your message
ansible-playbook error-controls.yml -e disk_usage_limit=1     # failed_when trips on disk usage
```

## 🧠 When to use what

| Situation | Use |
| --- | --- |
| A deployment step fails and you must undo it | `block` + `rescue` |
| Cleanup must always happen (remove temp files, unlock) | `always` |
| A service takes time to come up | `retries` + `until` |
| A command's exit code doesn't match "success" | `failed_when` |
| A failure doesn't matter at all | `ignore_errors` (use sparingly: it hides real problems) |
| Bad input should stop everything early | `assert` |
| One host failing must stop **all** hosts | `any_errors_fatal: true` on the play |

## 🧪 Try it yourself

1. In another terminal run `python3 -m http.server 8099`, change the URL in task 5 to `/`, and watch it succeed.
2. Add `any_errors_fatal: true` to the play in `resilient-deploy.yml`. When does it matter? (With many hosts.)
3. Add a second `rescue` task that writes the failure details to `/tmp/lab14/last_error.txt`.

## 🔍 Verify

After the default run, `cat /tmp/lab14/app/version.txt` shows `version=1.0` (rolled back); after
`-e simulate_failure=false` it shows `version=2.0`.

## 🧹 Clean up

```bash
rm -rf /tmp/lab14
```

➡️ **Next:** [Lab 15: Jinja2 templates](../lab15-jinja2-templates/)
