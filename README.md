# Ansible Labs: 20 hands-on labs from zero to multi-cloud

[![CI](https://github.com/Hassan6586/Ansible-Labs/actions/workflows/ci.yml/badge.svg)](https://github.com/Hassan6586/Ansible-Labs/actions/workflows/ci.yml)
![ansible-core](https://img.shields.io/badge/ansible--core-2.17%2B-EE0000?logo=ansible)
![Ubuntu](https://img.shields.io/badge/tested%20on-Ubuntu%2024.04-E95420?logo=ubuntu&logoColor=white)
![Level](https://img.shields.io/badge/level-beginner%20%E2%86%92%20advanced-2ea44f)

A practical, beginner-friendly path through **Ansible**, the automation tool DevOps teams use to configure
servers, deploy apps and manage cloud infrastructure. Every lab has real, runnable code, the output you
should expect, exercises, a troubleshooting guide and interview questions.

> You don't need any Ansible experience. If you can use a Linux terminal (`cd`, `ls`, edit a file), you can
> start with Lab 01.

## 🗺️ The labs

| # | Lab | You'll learn | Needs |
| --- | --- | --- | --- |
| 01 | [Introduction to Ansible](lab01-introduction-to-ansible/) | Install, inventory, `ansible.cfg`, SSH keys, ad-hoc commands | 💻 |
| 02 | [Your first playbook](lab02-first-playbook/) | Plays, tasks, modules, `become`, installing packages | 💻 🔑 |
| 03 | [Managing inventory](lab03-managing-inventory/) | INI vs YAML, groups, `group_vars`/`host_vars`, patterns, dynamic scripts | 💻 |
| 04 | [Roles](lab04-ansible-roles/) | Role structure, defaults, handlers, templates | 💻 🔑 |
| 05 | [Variables and facts](lab05-variables-and-facts/) | Variable sources and precedence, facts, `when` | 💻 |
| 06 | [Ansible Vault](lab06-ansible-vault/) | Encrypt files and strings, `no_log`, password files | 💻 |
| 07 | [Idempotence](lab07-idempotence/) | Why re-running is safe, `creates`, `changed_when` | 💻 |
| 08 | [Docker](lab08-docker-with-ansible/) | Install Docker, images, networks, containers | 💻 🔑 🐳 |
| 09 | [AWS EC2 provisioning](lab09-aws-ec2-provisioning/) | Key pair, security group, EC2 instance, then configure it | ☁️ |
| 10 | [Kubernetes](lab10-ansible-with-kubernetes/) | kind cluster, `kubernetes.core.k8s`, waiting, `k8s_info` | 🐳 ☸️ |
| 11 | [CI/CD with Jenkins](lab11-cicd-with-jenkins/) | Release folders, symlink switch, a Jenkins pipeline | 💻 |
| 12 | [Multi-tier application](lab12-multi-tier-application/) | Redis + Python app + nginx with three roles and tags | 💻 🔑 |
| 13 | [Security hardening](lab13-security-hardening/) | SSH hardening, UFW, fail2ban, audit and rollback | 💻 🔑 |
| 14 | [Error handling and blocks](lab14-error-handling-and-blocks/) | `block`/`rescue`/`always`, `failed_when`, retries | 💻 |
| 15 | [Jinja2 templates](lab15-jinja2-templates/) ✨ | Variables, loops, conditions and filters in templates | 💻 |
| 16 | [Loops and advanced playbooks](lab16-loops-and-advanced-playbooks/) | `loop`, `dict2items`, `loop_control`, `include_tasks`, tags | 💻 🔑 |
| 17 | [AWX (Automation Controller)](lab17-awx-automation-controller/) | AWX Operator, projects, inventories, job templates | 🐳 ☸️ |
| 18 | [Kubernetes scaling and lifecycle](lab18-kubernetes-scaling-and-lifecycle/) | Scale, rolling update, rollback, delete | 🐳 ☸️ |
| 19 | [Hybrid cloud automation](lab19-hybrid-cloud-automation/) | On-prem + cloud groups, `hostvars`, `delegate_to`, `run_once` | 💻 |
| 20 | [Multi-cloud inventories](lab20-multi-cloud-inventories/) | `aws_ec2` and `azure_rm` plugins, `constructed`, `keyed_groups` | 💻 ☁️ |

**Needs:** 💻 one Ubuntu machine · 🔑 `sudo` · 🐳 Docker · ☸️ a local Kubernetes cluster · ☁️ an AWS account
(free tier is enough; remember to clean up)

✨ Lab 15 is new: the original lab list skipped from 14 to 16, so this repository adds a Jinja2 templates lab
to complete the set.

## ✅ What you need

- **Ubuntu 22.04 or 24.04**: a VM (VirtualBox, Multipass), WSL2 on Windows, or a small cloud server
- At least **2 CPUs and 4 GB RAM** (Lab 17 needs **4 CPUs and 8 GB**)
- `git` and a text editor (VS Code with the Ansible extension is great)

## 🚀 Getting started

```bash
# 1. Install Ansible from the official PPA (see Lab 01 for details)
sudo apt update
sudo apt install -y software-properties-common git
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install -y ansible

# 2. Get the labs
git clone https://github.com/Hassan6586/Ansible-Labs.git ~/Ansible-Labs
cd ~/Ansible-Labs

# 3. (Optional) install every collection the labs use, in one go
ansible-galaxy collection install -r requirements.yml

# 4. Start with Lab 01
cd lab01-introduction-to-ansible
```

Labs 09, 10, 18 and 20 talk to cloud APIs and need newer Python libraries than Ubuntu ships. Lab 09 shows how
to create a small virtual environment for them:

```bash
python3 -m venv ~/ansible-cloud-venv
source ~/ansible-cloud-venv/bin/activate
pip install ansible boto3 botocore kubernetes
```

## 📁 How every lab is organised

```text
labNN-topic/
├── README.md            # the step-by-step guide: start here
├── ansible.cfg          # settings for this lab (so commands work from inside the folder)
├── inventory.ini        # the hosts this lab uses
├── *.yml                # playbooks
├── commands.sh          # every command from the guide, in order
├── troubleshooting.md   # common errors: why they happen and how to fix them
└── interview_qna.md     # 10 interview questions with answers
```

Each `README.md` follows the same pattern:

| Section | What's in it |
| --- | --- |
| 🎯 What you'll learn | The goals of the lab |
| 🧠 Key ideas in plain words | New terms, explained simply |
| ✅ Before you start | What to install or finish first |
| 🛠 Steps | Commands, code and the output you should see |
| 🧪 Try it yourself | Small exercises to check you really understood |
| 🔍 Verify | How to prove it worked |
| 🧹 Clean up | Undo everything the lab created |

## 🧭 Conventions

- **Modern Ansible.** Modules use their full names (`ansible.builtin.copy`, not `copy`), loops use `loop`
  (not `with_items`), and everything passes [`ansible-lint`](https://ansible.readthedocs.io/projects/lint/)
  with the strict `production` profile.
- **Safe by default.** Most labs run against your own machine (`localhost`) and write to `/tmp/labNN`, so you
  can't break a real server. Every lab has a clean-up step.
- **Idempotent.** Run any playbook twice: the second run should report `changed=0`.
- **No secrets in Git.** Vault password files and private keys are in `.gitignore`. Never commit them.

## 🧪 Continuous integration

Every push runs [GitHub Actions](.github/workflows/ci.yml):

1. `ansible-lint` on every lab, with the `production` profile
2. Runs the labs that need no cloud account (05, 07, 14, 15, 16, 19, 20) and checks that a second run reports
   `changed=0`

## 💡 Tips for learning

- **Type the commands** instead of copy-pasting, at least the first time.
- **Read the errors.** Ansible's error messages are usually clear. Each lab's `troubleshooting.md` covers the
  common ones.
- **Use `-v`, `-vv` or `-vvv`** to see more detail when something goes wrong.
- **`--check --diff`** shows what a playbook *would* change without changing it.
- **`ansible-doc <module>`** prints a module's documentation and examples, offline.

## 🤝 Contributing

Found a mistake, or a command that no longer works? Open an issue or a pull request. Please run
`ansible-lint` before you submit.

## 👤 Author

**Muhammad Hassan Javed**, DevOps and cloud engineer

- Website: [techwithhassan.cloud](https://techwithhassan.cloud)
- LinkedIn: [mhassanjaved](https://www.linkedin.com/in/mhassanjaved)
- GitHub: [@Hassan6586](https://github.com/Hassan6586)

If these labs helped you, please give the repository a ⭐.

## 📄 License

[MIT](LICENSE)
