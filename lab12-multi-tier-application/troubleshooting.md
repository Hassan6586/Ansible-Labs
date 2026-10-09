# Lab 12: Troubleshooting

| Problem | Why it happens | Fix |
| --- | --- | --- |
| `Wait for the app's health check` fails after retries | The app crashed or can't reach Redis. | `journalctl -u visit-counter -n 30` and `systemctl status redis-server`. |
| nginx fails: `bind() to 0.0.0.0:8088 failed (98: Address already in use)` | Something already uses port 8088. | `sudo ss -ltnp \| grep 8088`; change `webserver_listen_port`. |
| nginx fails on port 80 | The default site is still enabled and Apache (Lab 04) holds port 80. | The role removes the default site; also run Lab 04's `cleanup.yml`. |
| `nginx: [emerg] ...` at the `nginx -t` task | Typo in the site template. | Read the error line number; fix `visit-counter.conf.j2`. |
| `502 Bad Gateway` from nginx | nginx works but the app isn't running on 8000. | `systemctl restart visit-counter`; check its logs. |
| `ModuleNotFoundError: No module named 'redis'` in the app logs | `python3-redis` isn't installed. | Re-run with `--tags application`. |
| `--tags application` skips everything | Tag names are case-sensitive and must match. | List them with `ansible-playbook site.yml --list-tags`. |
