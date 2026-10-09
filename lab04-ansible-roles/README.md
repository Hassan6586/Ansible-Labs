# Lab 04: Using Ansible roles

As playbooks grow, putting everything in one file gets messy. A **role** packages related tasks, handlers,
templates and default variables into a standard folder structure that you can reuse in any playbook.

## 🎯 What you'll learn

- The standard role folder layout and what each folder is for
- Templates (`.j2` files) and **handlers** that run only when something changed
- How role **defaults** work and how to override them
- Creating a role skeleton with `ansible-galaxy role init`

## 🧠 Key ideas in plain words

| Folder | What goes in it |
| --- | --- |
| `tasks/main.yml` | The steps the role runs |
| `handlers/main.yml` | Actions that run only when notified, such as "restart the service" |
| `templates/` | Jinja2 template files (`.j2`) that become config files |
| `defaults/main.yml` | Default variables, the **easiest** to override |
| `vars/main.yml` | Role variables that are **hard** to override (not used here) |
| `files/` | Static files to copy as they are |
| `meta/main.yml` | Author, supported platforms and dependencies on other roles |

A **handler** answers the question "only restart Apache if its config actually changed". A task says
`notify: Restart web server`, and the handler runs once at the end of the play, only if that task reported
`changed`.

## ✅ Before you start

- Labs 01–02 completed
- Port 80 free on your machine

```bash
cd ~/Ansible-Labs/lab04-ansible-roles
```

## 🛠 Step 1: See what a role skeleton looks like

```bash
ansible-galaxy role init /tmp/demo_role
tree /tmp/demo_role
rm -rf /tmp/demo_role
```

`ansible-galaxy` creates every folder. Our role keeps only the ones it needs:

```text
roles/webserver/
├── defaults/main.yml      # variables you can override
├── handlers/main.yml      # "Restart web server"
├── meta/main.yml          # role information
├── tasks/main.yml         # install, template, start
└── templates/index.html.j2
```

## 🛠 Step 2: Read the role

**`defaults/main.yml`**

```yaml
webserver_package: apache2
webserver_service: apache2
webserver_page_title: "Configured by Ansible"
webserver_owner: "Hassan's DevOps Lab"
```

> 💡 Start every role variable with the role name (`webserver_...`). That avoids clashes with other roles.

**`tasks/main.yml`**

```yaml
- name: Install the web server package
  ansible.builtin.apt:
    name: "{{ webserver_package }}"
    state: present
    update_cache: true
    cache_valid_time: 3600

- name: Deploy the home page from a template
  ansible.builtin.template:
    src: index.html.j2
    dest: /var/www/html/index.html
    mode: "0644"
  notify: Restart web server

- name: Make sure the web server is running and starts on boot
  ansible.builtin.service:
    name: "{{ webserver_service }}"
    state: started
    enabled: true
```

Notice `src: index.html.j2`: inside a role, Ansible automatically looks in the role's `templates/` folder.

**`templates/index.html.j2`** fills in variables and facts:

```html
<h1>{{ webserver_page_title }}</h1>
<p>Host: {{ ansible_facts['hostname'] }}</p>
<p>Owner: {{ webserver_owner }}</p>
```

## 🛠 Step 3: Use the role in a playbook

`webserver-playbook.yml`:

```yaml
- name: Deploy a web server with a role
  hosts: local
  become: true
  roles:
    - role: webserver
      vars:
        webserver_page_title: "Hello from my first Ansible role"
```

```bash
ansible-playbook webserver-playbook.yml --syntax-check
ansible-playbook webserver-playbook.yml -K
```

The first run installs Apache, writes the page and runs the **RUNNING HANDLER [webserver : Restart web server]**
step. Run it again: `changed=0`, and the handler does **not** run because nothing changed.

## 🛠 Step 4: Override a default and trigger the handler

```bash
ansible-playbook webserver-playbook.yml -K -e webserver_owner="Your Name"
curl -s http://localhost | grep Owner
```

`-e` (extra vars) has the highest priority of all, so it beats the role default. The page changes, so the handler
runs again.

## 🔍 Verify

```bash
curl -s http://localhost | grep -E "<h1>|Host:"
systemctl is-active apache2      # prints "active"
```

Or open `http://localhost` (or your VM's IP) in a browser.

## 🧹 Clean up

Lab 12 runs its own web server, so remove Apache when you're done:

```bash
ansible-playbook cleanup.yml -K
```

➡️ **Next:** [Lab 05: Variables and facts](../lab05-variables-and-facts/)
