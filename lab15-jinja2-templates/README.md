# Lab 15: Jinja2 templates

> ℹ️ The original lab list jumped from 14 to 16. This lab fills the gap with a topic every Ansible user needs:
> **templates**.

Real servers need config files that are *almost* the same everywhere: a different port here, an extra
server there, debug on in staging and off in production. Instead of keeping one file per server, you keep
**one template** and let Ansible fill in the blanks with variables and facts.

## 🎯 What you'll learn

- The three Jinja2 tags: `{{ }}`, `{% %}` and `{# #}`
- `if` / `else` and `for` loops inside a template
- Useful filters: `default`, `upper`, `join`, `length`, `map`, `selectattr`, `dict2items`, `to_nice_json`
- `ansible_managed`, `--check --diff`, and whitespace control with `-`
- How to render the same template differently for staging and production

## 🧠 Key ideas in plain words

| Syntax | Meaning | Example |
| --- | --- | --- |
| `{{ ... }}` | Print a value | `{{ app_name }}` → `orders-api` |
| `{% ... %}` | Logic: `if`, `for`, `set` | `{% if debug_mode %}...{% endif %}` |
| `{# ... #}` | Comment that never reaches the output file | `{# note to self #}` |
| `\|` (pipe) | Pass a value through a filter | `{{ admins \| join(', ') }}` |
| `.j2` | File extension for templates (just a convention) | `app.conf.j2` |
| `template` module | Renders a `.j2` file and copies the result to the host | `src: app.conf.j2` |

> 💡 `copy` sends a file exactly as it is. `template` runs it through Jinja2 first. If the file has no
> `{{ }}` in it, use `copy`.

## ✅ Before you start

No sudo needed. Everything is written to `/tmp/lab15`.

```bash
cd ~/Ansible-Labs/lab15-jinja2-templates
```

Folder layout:

```text
lab15-jinja2-templates/
├── vars.yml                    # the data the templates use
├── render-templates.yml        # renders all four templates
├── filters-playground.yml      # try filters without writing files
└── templates/
    ├── app.conf.j2             # if/else, default, upper, join
    ├── nginx-upstream.conf.j2  # for loop over a list of servers
    ├── features.json.j2        # build JSON with filters
    └── report.txt.j2           # sort, format, whitespace control
```

## 🛠 Step 1: Look at the data

`vars.yml` holds everything the templates need:

```yaml
app_name: orders-api
environment_name: staging          # try: production
app_port: 8080
debug_mode: false
log_level: info

backend_servers:
  - { name: app1, ip: 10.0.1.11, weight: 3 }
  - { name: app2, ip: 10.0.1.12, weight: 1 }
  - { name: app3, ip: 10.0.1.13, weight: 1, backup: true }

feature_flags:
  new_checkout: true
  dark_mode: false
  beta_reports: true

admins: [hassan, ayesha, bilal]
```

## 🛠 Step 2: Your first template (variables, if/else, filters)

`templates/app.conf.j2`:

```jinja
# {{ ansible_managed }}
# Rendered for {{ inventory_hostname }} on {{ ansible_facts['distribution'] }}

[app]
name = {{ app_name }}
environment = {{ environment_name | upper }}
port = {{ app_port }}
{# This is a Jinja2 comment: it does NOT appear in the output file #}
{% if environment_name == 'production' %}
log_level = warning
workers = {{ ansible_facts['processor_vcpus'] * 2 }}
{% else %}
log_level = {{ log_level }}
workers = 2
{% endif %}
debug = {{ debug_mode | lower }}

[database]
host = {{ db_host | default('localhost') }}
port = {{ db_port | default(5432) }}

[admins]
users = {{ admins | join(', ') }}
count = {{ admins | length }}
```

What's going on:

- `ansible_managed` prints a "this file is managed by Ansible" line, so nobody edits it by hand.
- `ansible_facts[...]` comes from fact gathering (Lab 5). Production gets 2 workers per CPU.
- `db_host` isn't defined anywhere, so `default('localhost')` kicks in instead of an error.

## 🛠 Step 3: Loops (`nginx-upstream.conf.j2`)

```jinja
upstream {{ app_name }} {
{% for server in backend_servers %}
    server {{ server.ip }}:{{ app_port }} weight={{ server.weight }}{{ ' backup' if server.backup | default(false) else '' }};  # {{ server.name }}
{% endfor %}
}
```

Add a server to `backend_servers` and it appears in the config. No copy-pasting.

## 🛠 Step 4: Render everything

`render-templates.yml` loops over the four templates:

```yaml
- name: Render every template
  ansible.builtin.template:
    src: "{{ item }}.j2"
    dest: "{{ output_dir }}/{{ item }}"
    mode: "0644"
  loop:
    - app.conf
    - nginx-upstream.conf
    - features.json
    - report.txt
```

```bash
ansible-playbook render-templates.yml
cat /tmp/lab15/app.conf
```

```text
# Ansible managed
# Rendered for localhost on Ubuntu

[app]
name = orders-api
environment = STAGING
port = 8080
log_level = info
workers = 2
debug = false

[database]
host = localhost
port = 5432

[admins]
users = hassan, ayesha, bilal
count = 3
```

```bash
cat /tmp/lab15/nginx-upstream.conf
```

```text
# Ansible managed
upstream orders-api {
    server 10.0.1.11:8080 weight=3;  # app1
    server 10.0.1.12:8080 weight=1;  # app2
    server 10.0.1.13:8080 weight=1 backup;  # app3
}
...
```

```bash
cat /tmp/lab15/features.json
```

```json
{
    "app": "orders-api",
    "backend_count": 3,
    "enabled_features": [
        "new_checkout",
        "beta_reports"
    ],
    "environment": "staging"
}
```

The JSON template builds a dictionary and lets `to_nice_json` produce valid JSON, so there are no missing
commas or quotes to worry about.

```bash
cat /tmp/lab15/report.txt
```

```text
Backend report for orders-api
==============================
1. app1   10.0.1.11
2. app2   10.0.1.12
3. app3   10.0.1.13  (backup)
==============================
Primary servers: app1, app2
Total weight:    5
Feature flags on: 2 of 3
```

Run it a second time: every task says `ok` and the recap shows `changed=0`. Templates are idempotent: the
file is only rewritten when the rendered result is different.

## 🛠 Step 5: Same template, different environment

Preview the change first with `--check --diff` (nothing is written):

```bash
ansible-playbook render-templates.yml -e environment_name=production --check --diff
```

```diff
-environment = STAGING
+environment = PRODUCTION
 port = 8080
-log_level = info
-workers = 2
+log_level = warning
+workers = 4
...
-    server_name orders-api.staging.example.com;
+    server_name orders-api.production.example.com;
```

`--diff` is the best way to check a template change before it reaches a real server. (The number of workers
depends on your CPU count.)

## 🛠 Step 6: The filter playground

`filters-playground.yml` prints filter results without writing any files. Change things and re-run.

```bash
ansible-playbook filters-playground.yml
```

```text
TASK [Strings]
    - ORDERS-API
    - orders_api
    - Hello orders-api
    - orders

TASK [Lists of dictionaries]
    -   - 10.0.1.11
        - 10.0.1.12
        - 10.0.1.13
    -   - app1
    - 5

TASK [Defaults and types]
    - fallback value
    - 50
    - true
    - '{"a": 1}'
```

## 🧠 Filter cheat sheet

| Filter | Example | Result |
| --- | --- | --- |
| `default` | `{{ x \| default('none') }}` | `none` if `x` is undefined |
| `upper` / `lower` | `{{ 'dev' \| upper }}` | `DEV` |
| `join` | `{{ ['a','b'] \| join(', ') }}` | `a, b` |
| `length` | `{{ admins \| length }}` | `3` |
| `map(attribute=)` | `{{ servers \| map(attribute='ip') \| list }}` | list of IPs |
| `selectattr` | `{{ servers \| selectattr('weight','gt',1) \| list }}` | only matching items |
| `dict2items` | `{{ flags \| dict2items }}` | `[{key:..., value:...}]` |
| `to_nice_json` / `to_nice_yaml` | `{{ data \| to_nice_json }}` | pretty JSON / YAML |
| `int` / `bool` | `{{ '42' \| int }}` | turns text into a number / boolean |
| `format` | `{{ '%-6s' \| format(name) }}` | pads text to 6 characters |

## 🧪 Try it yourself

1. Add `- { name: app4, ip: 10.0.1.14, weight: 2 }` to `vars.yml` and render again. Which files change?
2. Set `debug_mode: true` and add `{% if debug_mode %}trace = on{% endif %}` to `app.conf.j2`.
3. Add `db_host: db.internal` to `vars.yml`. What happens to the `default()`?
4. Write a `hosts.j2` template that prints `<ip> <name>` for every backend server (like `/etc/hosts`).
5. Add `validate: "python3 -m json.tool %s"` to a template task for `features.json` so a broken JSON file is
   never written.

## 🔍 Verify

```bash
ls /tmp/lab15                                  # app.conf  features.json  nginx-upstream.conf  report.txt
python3 -m json.tool /tmp/lab15/features.json  # valid JSON
ansible-playbook render-templates.yml          # second run: changed=0
```

## 🧹 Clean up

```bash
rm -rf /tmp/lab15
```

➡️ **Next:** [Lab 16: Loops and advanced playbooks](../lab16-loops-and-advanced-playbooks/)
