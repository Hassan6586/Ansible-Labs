# Lab 01: Troubleshooting

| Problem | Why it happens | Fix |
| --- | --- | --- |
| `error: externally-managed-environment` when running `pip3 install ansible` | Ubuntu 23.04+ protects the system Python from pip. | Install from the PPA (Step 1), or use `pipx install --include-deps ansible`. |
| `add-apt-repository: command not found` | The helper package isn't installed. | `sudo apt install -y software-properties-common` |
| `lab-node \| UNREACHABLE! ... Connection refused` | No SSH server is running. | `sudo apt install -y openssh-server && sudo systemctl enable --now ssh` |
| `UNREACHABLE! ... Permission denied (publickey,password)` | The key isn't in `~/.ssh/authorized_keys`, or permissions are too open. | Re-run the `cat ... >> ~/.ssh/authorized_keys` and `chmod` commands from Step 2, then test with plain `ssh -i ~/.ssh/ansible_key $USER@127.0.0.1`. |
| `[WARNING]: Ansible is being run in a world writable directory ... ignoring it as an ansible.cfg source` | Ansible ignores config files in folders anyone can write to (common on WSL `/mnt/c/...`). | Clone the repo inside your Linux home folder (`~/Ansible-Labs`), not under `/mnt/c`. |
| `Missing sudo password` | The task needs root (`--become`) and you didn't give the password. | Add `--ask-become-pass` (or `-K`). |
| `[WARNING]: No inventory was parsed` | You ran the command outside the lab folder, so `ansible.cfg` wasn't found. | `cd` into the lab folder, or pass `-i inventory.ini`. |
| `/usr/bin/python3: not found` on a managed node | Python isn't installed on that machine. | `sudo apt install -y python3` on the managed node. |

**Tip:** add `-v`, `-vv` or `-vvv` to any command to see more detail about what Ansible is doing.
