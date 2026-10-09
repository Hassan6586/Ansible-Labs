# Lab 08: Troubleshooting

| Problem | Why it happens | Fix |
| --- | --- | --- |
| `couldn't resolve module/action 'community.docker.docker_container'` | The collection isn't installed. | `ansible-galaxy collection install -r requirements.yml` |
| `Error connecting: ... Permission denied` (docker.sock) | Your user can't use Docker yet. | Run the playbook with `become: true`/`-K`, or log out and back in after Step 2. |
| `Error connecting: ... No such file or directory` (docker.sock) | Docker isn't running. | `sudo systemctl start docker`, then `sudo systemctl status docker`. |
| `Bind for 0.0.0.0:8080 failed: port is already allocated` | Something else uses port 8080. | `sudo ss -ltnp \| grep 8080`; stop it or use `-e app_port=8081`. |
| `toomanyrequests: You have reached your pull rate limit` | Docker Hub limits anonymous pulls. | Wait, or `sudo docker login`. |
| The `uri` check fails after all retries | The container exited or the page is missing. | `sudo docker logs lab-nginx`; check `/opt/lab08/html/index.html`. |
| The container is recreated on every run | A setting differs from the running container (for example an unpinned image that changed). | Pin image tags and compare `docker inspect` with your task. |
