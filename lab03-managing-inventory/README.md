# Lab 03: Managing Ansible inventory

The inventory tells Ansible **which machines exist**, **how to group them** and **what settings each one gets**.
Good inventory design is what lets one playbook work for staging and production.

> This lab only **reads** inventories, so you don't need any extra servers. The IP addresses are examples.

## 🎯 What you'll learn

- Writing inventories in INI and YAML format
- Groups, nested groups (`children`) and the special groups `all` and `ungrouped`
- Putting variables in `group_vars/` and `host_vars/`, and which one wins
- Host patterns: `web*`, `group1:group2`, `group:!other`, `group:&other`
- How a **dynamic inventory** script works

## 🧠 Key ideas in plain words

| Term | What it means |
| --- | --- |
| **Group** | A named set of hosts, such as `webservers`. A host can be in many groups. |
| **Children** | Groups inside a group. `production` contains `webservers` and `databases`. |
| **`group_vars/<group>.yml`** | Variables for every host in that group. |
| **`host_vars/<host>.yml`** | Variables for one host. These beat group variables. |
| **Dynamic inventory** | A script or plugin that builds the host list on the fly, for example from AWS. |

## ✅ Before you start

```bash
cd ~/Ansible-Labs/lab03-managing-inventory
```

Folder layout:

```text
inventories/
├── ini/hosts.ini                  # INI format example
├── production/
│   ├── hosts.yml                  # YAML inventory (the default for this lab)
│   ├── group_vars/
│   │   ├── all.yml                # every host
│   │   ├── production.yml         # hosts in "production"
│   │   ├── webservers.yml
│   │   └── databases.yml
│   └── host_vars/
│       └── web1.yml               # only web1
└── dynamic/dynamic_inventory.py   # a dynamic inventory script
```

> 💡 `group_vars/` and `host_vars/` must sit **next to the inventory file** (or next to the playbook). Ansible won't
> find them anywhere else.

## 🛠 Step 1: An INI inventory

`inventories/ini/hosts.ini`:

```ini
[webservers]
web1 ansible_host=192.168.1.10
web2 ansible_host=192.168.1.11

[databases]
db1 ansible_host=192.168.1.20

[production:children]
webservers
databases

[production:vars]
env_type=production
```

```bash
ansible-inventory -i inventories/ini/hosts.ini --graph
```

```text
@all:
  |--@ungrouped:
  |--@production:
  |  |--@webservers:
  |  |  |--web1
  |  |  |--web2
  |  |--@databases:
  |  |  |--db1
```

## 🛠 Step 2: The same in YAML, plus a staging group

`inventories/production/hosts.yml`:

```yaml
all:
  children:
    production:
      children:
        webservers:
          hosts:
            web1:
              ansible_host: 192.168.1.10
            web2:
              ansible_host: 192.168.1.11
        databases:
          hosts:
            db1:
              ansible_host: 192.168.1.20
    staging:
      hosts:
        stage-web1:
          ansible_host: 10.10.0.10
```

This is the default inventory in `ansible.cfg`, so no `-i` is needed:

```bash
ansible-inventory --graph
```

## 🛠 Step 3: Variables from group_vars and host_vars

`webservers.yml` sets `max_clients: 200`, but `host_vars/web1.yml` sets `max_clients: 500`. Which one does web1 get?

```bash
ansible-inventory --host web1
```

```json
{
    "ansible_host": "192.168.1.10",
    "env_type": "production",
    "http_port": 80,
    "max_clients": 500,
    "monitoring_enabled": true,
    "ntp_server": "time.google.com"
}
```

- `max_clients` is **500**: host variables beat group variables.
- `monitoring_enabled` is **true**: `production.yml` (a specific group) beats `all.yml`.

Now see every host's final values with a small playbook:

```bash
ansible-playbook show-vars.yml
```

```text
ok: [web1] =>
    msg: web1 (192.168.1.10) env=production groups=production,webservers max_clients=500 db_port=n/a
ok: [web2] =>
    msg: web2 (192.168.1.11) env=production groups=production,webservers max_clients=200 db_port=n/a
ok: [db1] =>
    msg: db1 (192.168.1.20) env=production groups=databases,production max_clients=n/a db_port=5432
```

The order, from **lowest** to **highest** priority, for inventory variables is:

```text
group_vars/all  →  group_vars/<parent group>  →  group_vars/<child group>  →  host_vars/<host>
```

## 🛠 Step 4: Pick hosts with patterns

```bash
ansible all --list-hosts                          # every host
ansible 'webservers:databases' --list-hosts       # in either group (OR)
ansible 'production:!databases' --list-hosts      # production but NOT databases
ansible 'production:&webservers' --list-hosts     # in BOTH groups (AND)
ansible 'web*' --list-hosts                       # name starts with "web"
ansible all --limit web1 --list-hosts             # restrict any command to one host
```

> Always put patterns in single quotes so your shell doesn't treat `!` or `*` specially.

## 🛠 Step 5: A dynamic inventory

In the cloud, servers come and go, so a fixed file goes stale. A **dynamic inventory** asks an API instead.
Ansible runs the script with `--list` and reads JSON:

```bash
./inventories/dynamic/dynamic_inventory.py --list
ansible-inventory -i inventories/dynamic/dynamic_inventory.py --graph
```

```text
@all:
  |--@ungrouped:
  |--@webservers:
  |  |--app-node-1
  |  |--app-node-2
  |--@databases:
  |  |--db-node-1
```

The `_meta.hostvars` section in the JSON gives every host's variables in one go, so Ansible doesn't need to call
the script once per host. In Lab 20 you'll use real inventory **plugins** for AWS and Azure, which do the same job.

You can also combine inventories:

```bash
ansible-inventory -i inventories/production/hosts.yml -i inventories/dynamic/dynamic_inventory.py --graph
```

## 🧪 Try it yourself

1. Add `web3` with IP `192.168.1.12` to `webservers` and confirm it gets `max_clients: 200`.
2. Create `host_vars/db1.yml` that sets `backup_schedule: "03:30"` and check it with `ansible-inventory --host db1`.
3. Add a `monitoring` group whose children are `webservers` and `databases`.

## 🔍 Verify

`ansible-inventory --host web1` shows `max_clients: 500`, and `ansible 'production:!databases' --list-hosts` lists
only `web1` and `web2`.

## 🧹 Clean up

Nothing to clean up: this lab didn't change your machine.

➡️ **Next:** [Lab 04: Using Ansible roles](../lab04-ansible-roles/)
