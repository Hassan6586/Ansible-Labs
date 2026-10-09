# Lab 19: Hybrid cloud automation

Many companies run some servers in their **own data centre** (on-premises) and others in a **public cloud**.
That's a *hybrid* setup. The good news: Ansible doesn't care where a server lives. One inventory and one
playbook can manage both, using groups for the parts that differ.

In this lab both "servers" are your own machine (`ansible_connection: local`), so you can run everything for
free. The structure is exactly what you'd use with real servers.

## 🎯 What you'll learn

- A YAML inventory with an `onpremises` group and a `cloud` group
- `group_vars` per environment: same variable names, different values
- Separate plays per group in one playbook
- Reading another host's variables with `hostvars` and `groups`
- `delegate_to` (run a task on another host) and `run_once`
- `--limit` to work on one environment only

## 🧠 Key ideas in plain words

| Thing | What it does |
| --- | --- |
| `groups['cloud']` | The list of host names in the `cloud` group |
| `hostvars['local-db']` | All variables of another host, e.g. its IP |
| `delegate_to: local-db` | Run this task **on** `local-db`, but in the loop of the current host |
| `run_once: true` | Run the task one time in total, not once per host |
| `--limit cloud` | Only touch hosts in the `cloud` group this time |

## ✅ Before you start

No sudo, no cloud account. Output goes to `/tmp/lab19`.

```bash
cd ~/Ansible-Labs/lab19-hybrid-cloud-automation
```

```text
inventory.yml            # two groups: onpremises and cloud
group_vars/all.yml       # shared by everyone
group_vars/onpremises.yml
group_vars/cloud.yml
templates/node-info.txt.j2
templates/app.env.j2
hybrid-deploy.yml
cleanup.yml
```

## 🛠 Step 1: The inventory

`inventory.yml`:

```yaml
all:
  vars:
    ansible_connection: local
  children:
    onpremises:
      hosts:
        local-db:
          private_ip: 192.168.10.20
          role: database
    cloud:
      hosts:
        cloud-web:
          private_ip: 10.0.1.15
          role: web
```

```bash
ansible-inventory --graph
```

```text
@all:
  |--@ungrouped:
  |--@onpremises:
  |  |--local-db
  |--@cloud:
  |  |--cloud-web
```

## 🛠 Step 2: Same names, different values

Both group files define the same variables. Each host gets the values of its own group:

| Variable | `group_vars/onpremises.yml` | `group_vars/cloud.yml` |
| --- | --- | --- |
| `location` | Karachi data centre | AWS us-east-1 |
| `provider` | on-premises (VMware) | aws |
| `backup_target` | /mnt/nas/backups | s3://acme-backups |
| `log_shipping` | syslog | cloudwatch |

See every variable one host ends up with:

```bash
ansible-inventory --host cloud-web
```

```json
{
    "backup_target": "s3://acme-backups",
    "company": "Acme",
    "location": "AWS us-east-1",
    "log_shipping": "cloudwatch",
    "ntp_server": "time.google.com",
    "private_ip": "10.0.1.15",
    "provider": "aws",
    "role": "web",
    ...
}
```

Because the names are the same, one template works for both (`templates/node-info.txt.j2`):

```jinja
Location:      {{ location }}
Backups go to: {{ backup_target }}
Logs go to:    {{ log_shipping }}
```

## 🛠 Step 3: The playbook

`hybrid-deploy.yml` has four plays:

1. **all**: a baseline that every host gets
2. **onpremises**: database settings, allowing every cloud web server's IP:

   ```yaml
   allowed_clients = {{ groups['cloud'] | map('extract', hostvars, 'private_ip') | join(',') }}
   ```

3. **cloud**: the app needs the database IP, which belongs to *another* host. `hostvars` reads it:

   ```jinja
   DB_HOST={{ hostvars[db_host]['private_ip'] }}
   ```

   Then the web server asks the database host to open its firewall, with `delegate_to`:

   ```yaml
   - name: Ask the database host to allow this web server (delegate_to)
     ansible.builtin.lineinfile:
       path: "{{ output_root }}/{{ db_host }}/firewall-allow.txt"
       line: "allow {{ private_ip }} from {{ inventory_hostname }} ({{ location }})"
       create: true
     delegate_to: "{{ db_host }}"
   ```

4. **summary**: one report for the whole estate, using `run_once`

```bash
ansible-playbook hybrid-deploy.yml
```

```text
PLAY [Common baseline for every host (on-prem and cloud)]
TASK [Create a folder per host]
changed: [cloud-web]
changed: [local-db]
...
PLAY [Cloud web tier]
TASK [Point the app at the on-prem database (cross-environment lookup)]
changed: [cloud-web]
TASK [Ask the database host to allow this web server (delegate_to)]
changed: [cloud-web -> local-db]

PLAY [Hybrid summary (runs once, not once per host)]
TASK [Print where every host lives]
ok: [local-db] => (item=local-db) =>
    msg: local-db (database) -> Karachi data centre
ok: [local-db] => (item=cloud-web) =>
    msg: cloud-web (web) -> AWS us-east-1

PLAY RECAP
cloud-web : ok=4  changed=4  unreachable=0  failed=0
local-db  : ok=4  changed=3  unreachable=0  failed=0
```

Notice `cloud-web -> local-db`: the task belongs to `cloud-web` but ran on `local-db`.

## 🛠 Step 4: Look at the results

```bash
find /tmp/lab19 -type f | sort
cat /tmp/lab19/cloud-web/app.env
cat /tmp/lab19/local-db/firewall-allow.txt
```

```text
/tmp/lab19/cloud-web/app.env
/tmp/lab19/cloud-web/node-info.txt
/tmp/lab19/local-db/database.conf
/tmp/lab19/local-db/firewall-allow.txt
/tmp/lab19/local-db/node-info.txt

DB_HOST=192.168.10.20
DB_LOCATION=Karachi data centre
APP_LOCATION=AWS us-east-1

allow 10.0.1.15 from cloud-web (AWS us-east-1)
```

## 🛠 Step 5: Work on one environment only

```bash
ansible-playbook hybrid-deploy.yml --limit cloud
ansible cloud -m ansible.builtin.debug -a "var=log_shipping"
```

```text
cloud-web | SUCCESS =>
    log_shipping: cloudwatch
```

Even with `--limit cloud`, the cloud play can still read `local-db`'s variables and `delegate_to` it. Limits
decide which hosts are *targeted*, not which ones exist.

## 🧪 Try it yourself

1. Add a second cloud host `cloud-web-2` with `private_ip: 10.0.1.16`. Run again and look at
   `database.conf` and `firewall-allow.txt`.
2. Add an `azure` group with its own `group_vars/azure.yml` (`log_shipping: azure-monitor`).
3. Make `cloud` and `azure` children of a new parent group `public_cloud`, and give it shared vars.
4. Replace `cloud-web` with a real EC2 instance from Lab 09 (`ansible_host`, `ansible_user: ubuntu`, your key,
   and remove `ansible_connection: local` for it).

## 🔍 Verify

```bash
ansible-playbook hybrid-deploy.yml    # second run: changed=0 for both hosts
```

## 🧹 Clean up

```bash
ansible-playbook cleanup.yml
```

➡️ **Next:** [Lab 20: Multi-cloud inventories](../lab20-multi-cloud-inventories/)
