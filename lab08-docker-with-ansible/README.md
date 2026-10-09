# Lab 08: Managing Docker with Ansible

Ansible can install Docker itself and then manage images, networks and containers, all described as code.
That gives you repeatable container deployments on plain servers, without Kubernetes.

## 🎯 What you'll learn

- Installing **collections** (`community.docker`) with `ansible-galaxy`
- Installing Docker Engine with a playbook
- Pulling images and running containers with ports, volumes, networks and a restart policy
- Waiting for an app to be healthy with `uri` + `retries`/`until`
- Cleaning up everything the lab created

## 🧠 Key ideas in plain words

| Term | What it means |
| --- | --- |
| **Collection** | A package of Ansible modules and plugins. `community.docker` contains the Docker modules. |
| **`docker_container`** | Makes sure a container exists in the state you describe. If you change a setting, it recreates the container. |
| **Bind mount** (`volumes:`) | Shares a folder from the host into the container. Here it serves our HTML page. |
| **`retries` / `until`** | Repeat a task until a condition is true, such as "the website returns 200". |

## ✅ Before you start

- Port 8080 free
- About 200 MB of disk for Docker and the image

```bash
cd ~/Ansible-Labs/lab08-docker-with-ansible
```

## 🛠 Step 1: Install the collection

If you installed Ansible from the PPA (Lab 01), `community.docker` is already included. Installing it again makes
sure you have a recent version:

```bash
ansible-galaxy collection install -r requirements.yml
ansible-galaxy collection list community.docker
```

## 🛠 Step 2: Install Docker with Ansible

`install-docker.yml` installs `docker.io` and `python3-docker`, starts the service and adds you to the `docker`
group:

```bash
ansible-playbook install-docker.yml -K
docker --version
sudo docker ps
```

> 💡 Group changes apply at your next login. Until then, use `sudo docker ...`. The playbooks use `become: true`,
> so they work either way.

## 🛠 Step 3: Deploy a container

`deploy_containers.yml` (main part):

```yaml
- name: Pull the image
  community.docker.docker_image_pull:
    name: "{{ app_image }}"                 # nginx:1.27-alpine

- name: Create a Docker network for the lab
  community.docker.docker_network:
    name: lab08-net

- name: Run the nginx container
  community.docker.docker_container:
    name: "{{ app_name }}"
    image: "{{ app_image }}"
    state: started
    restart_policy: unless-stopped
    published_ports:
      - "{{ app_port }}:80"                 # host 8080 → container 80
    volumes:
      - "{{ content_dir }}:/usr/share/nginx/html:ro"
    networks:
      - name: lab08-net

- name: Wait until the site answers
  ansible.builtin.uri:
    url: "http://localhost:{{ app_port }}"
    return_content: true
  register: page
  retries: 10
  delay: 2
  until: page.status == 200
```

> 💡 Pin image versions (`nginx:1.27-alpine`, not `nginx:latest`). With `latest`, two runs a month apart can
> deploy different software.

```bash
ansible-playbook deploy_containers.yml -K
ansible-playbook deploy_containers.yml -K     # second run: changed=0
```

## 🛠 Step 4: Update the content

```bash
ansible-playbook deploy_containers.yml -K -e page_heading="Version 2 deployed by Ansible"
curl -s http://localhost:8080 | grep h1
```

Only the template task changes. The container keeps running and serves the new file straight away, because the
folder is mounted into it.

## 🧪 Try it yourself

1. Add a second container, `redis:7-alpine`, on the same `lab08-net` network.
2. Change `app_port` to `8081` and run again. What happens to the container? (It's recreated with the new port.)
3. Add `memory: 128m` to the nginx container and check with `sudo docker stats --no-stream`.

## 🔍 Verify

```bash
curl -s http://localhost:8080 | grep h1
sudo docker ps --filter name=lab-nginx
sudo docker inspect lab-nginx --format '{{ .HostConfig.RestartPolicy.Name }}'   # unless-stopped
```

## 🧹 Clean up

```bash
ansible-playbook cleanup.yml -K
```

Docker itself stays installed; Lab 10 uses it.

➡️ **Next:** [Lab 09: Provisioning AWS EC2](../lab09-aws-ec2-provisioning/)
