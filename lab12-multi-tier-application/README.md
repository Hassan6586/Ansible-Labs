# Lab 12: Deploying a multi-tier application

Real applications have layers: a **database**, an **application** server and a **web** server in front. In this
lab one playbook deploys all three, each as its own role, in the right order, and then checks the whole path
end to end.

```text
browser ──► nginx :8088 ──► Python app :8000 ──► Redis :6379
            (web tier)      (application tier)    (database tier)
```

The app is a visit counter: every page load increments a number stored in Redis.

## 🎯 What you'll learn

- Splitting a stack into roles: `database`, `application`, `webserver`
- One `site.yml` with a play per tier, in dependency order
- Running an app as a **systemd service** under its own system user
- `meta: flush_handlers` to apply restarts before testing
- Using **tags** to deploy one tier at a time
- An end-to-end health check

## 🧠 Key ideas in plain words

| Term | What it means |
| --- | --- |
| **Tier** | One layer of the app. Each tier would be its own server group in production. |
| **Reverse proxy** | nginx receives requests and forwards them to the app. It can add TLS, caching and load balancing later. |
| **systemd unit** | A service definition so Linux starts the app at boot and restarts it if it crashes. |
| **Tags** | Labels on plays or tasks so you can run only part of a playbook (`--tags application`). |

## ✅ Before you start

- Ports 6379, 8000 and 8088 free
- Labs 04 and 07 completed (roles and idempotence)

```bash
cd ~/Ansible-Labs/lab12-multi-tier-application
```

```text
roles/
├── database/       # Redis: install, configure (bind, port, maxmemory), run
├── application/    # Python app: user, code, systemd unit, health check
│   ├── files/app.py
│   └── templates/app.service.j2
└── webserver/      # nginx: reverse proxy site on port 8088
    └── templates/visit-counter.conf.j2
site.yml            # one play per tier + an end-to-end check
cleanup.yml
```

## 🛠 Step 1: Look at the inventory

```ini
[dbservers]
localhost ansible_connection=local

[appservers]
localhost ansible_connection=local

[webservers]
localhost ansible_connection=local
```

All three groups point at your machine. On real infrastructure you'd put different servers in each group and the
playbook wouldn't change. That's the point of grouping by **role**, not by machine.

## 🛠 Step 2: Read site.yml

```yaml
- name: Database tier
  hosts: dbservers
  become: true
  roles: [database]
  tags: [database]

- name: Application tier
  hosts: appservers
  become: true
  roles: [application]
  tags: [application]

- name: Web tier
  hosts: webservers
  become: true
  roles: [webserver]
  tags: [webserver]

- name: End-to-end check through the web tier
  hosts: webservers
  tags: [verify]
  tasks:
    - name: Request the page through nginx
      ansible.builtin.uri:
        url: "http://127.0.0.1:8088/"
        return_content: true
```

Highlights from the roles:

- **database**: sets `bind`, `port`, `maxmemory` and `maxmemory-policy` in `/etc/redis/redis.conf` with
  `lineinfile`; a change notifies **Restart Redis**.
- **application**: creates a `visitapp` system user with no login shell, installs `app.py` and a systemd unit,
  runs `meta: flush_handlers` so any restart happens **now**, then waits for `/health` to return 200.
- **webserver**: disables nginx's default site, writes the proxy config, runs `nginx -t` to validate it, and
  reloads nginx through a handler.

## 🛠 Step 3: Deploy

```bash
ansible-playbook site.yml --syntax-check
ansible-playbook site.yml -K
```

```text
TASK [Show the visit count]
    msg: 'Visits: 1'
```

Run it again: `changed=0` for every tier.

## 🛠 Step 4: Check each tier yourself

```bash
redis-cli ping                           # PONG
curl -s http://127.0.0.1:8000/health     # ok
curl -s http://localhost:8088/           # <h1>visit-counter</h1><p>Visits: 2</p>...
curl -s http://localhost:8088/           # Visits: 3
systemctl status visit-counter --no-pager
```

## 🛠 Step 5: Work on one tier with tags

```bash
ansible-playbook site.yml -K --tags database -e database_maxmemory=128mb
redis-cli config get maxmemory
```

Only the database play runs, and only **Restart Redis** fires. The app's visit count survives because the app
reconnects to Redis.

## 🧪 Try it yourself

1. Stop Redis (`sudo systemctl stop redis-server`) and open the page. Then run `site.yml` and watch it heal.
2. Add a second app instance on port 8001 and an nginx `upstream` block that load-balances between them.
3. Move `application_port` into `group_vars/appservers.yml` and use it in the webserver role's backend address.

## 🔍 Verify

`curl -s http://localhost:8088/` shows a visit count that goes up on every request.

## 🧹 Clean up

```bash
ansible-playbook cleanup.yml -K
```

➡️ **Next:** [Lab 13: Security hardening](../lab13-security-hardening/)
