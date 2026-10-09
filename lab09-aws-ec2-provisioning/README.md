# Lab 09: Provisioning AWS EC2 with Ansible

So far Ansible configured machines that already existed. Here it **creates** the machine too: an SSH key, a
firewall (security group) and an EC2 instance on AWS. Then, in the same playbook, it connects to the new server and
configures it.

> 💰 **This lab creates real AWS resources.** A `t3.micro` costs a few cents per hour (free-tier accounts may pay
> nothing). Always finish with Step 6 to delete everything.

## 🎯 What you'll learn

- Setting up a Python **virtual environment** for cloud modules
- Using the `amazon.aws` collection: `ec2_key`, `ec2_security_group`, `ec2_instance`
- Finding the latest AMI with an **SSM parameter lookup** instead of hard-coding an ID
- `add_host` + `wait_for_connection`: provision a server and configure it in one run
- Tagging resources and tearing them down cleanly

## 🧠 Key ideas in plain words

| Term | What it means |
| --- | --- |
| **EC2 instance** | A virtual server in AWS |
| **AMI** | The disk image a server starts from (here, Amazon Linux 2023) |
| **Security group** | A firewall around the instance. We allow SSH (port 22) from **your IP only**. |
| **Key pair** | The SSH key used to log in. AWS keeps the public half; you keep the `.pem` private key. |
| **boto3** | AWS's Python library. The `amazon.aws` modules use it to call the AWS API. |
| **`add_host`** | Adds a host to the inventory while the playbook runs, so a later play can connect to it. |

## ✅ Before you start

- An AWS account and an IAM user (or SSO) with EC2 permissions. Don't use the root account.
- Labs 01–07 completed

## 🛠 Step 1: A virtual environment for cloud modules

The `amazon.aws` collection needs **boto3 1.35 or newer**, but Ubuntu's `python3-boto3` package is older. A virtual
environment gives you current versions without touching the system Python:

```bash
sudo apt install -y python3-venv
python3 -m venv ~/ansible-cloud-venv
source ~/ansible-cloud-venv/bin/activate        # your prompt now starts with (ansible-cloud-venv)
pip install --upgrade pip
pip install ansible boto3 botocore
ansible --version
```

```bash
cd ~/Ansible-Labs/lab09-aws-ec2-provisioning
ansible-galaxy collection install -r requirements.yml
```

> 💡 Run `source ~/ansible-cloud-venv/bin/activate` again in every new terminal for Labs 09, 10, 18 and 20.
> The lab's `inventory.ini` uses `ansible_python_interpreter="{{ ansible_playbook_python }}"`, so modules run with
> the virtual environment's Python, where boto3 is installed.

## 🛠 Step 2: AWS credentials

```bash
sudo snap install aws-cli --classic
aws configure
#   AWS Access Key ID:     <your key>
#   AWS Secret Access Key: <your secret>
#   Default region name:   us-east-1
#   Default output format: json
aws sts get-caller-identity
```

`get-caller-identity` prints your account and user. If it works, Ansible will find the same credentials in
`~/.aws/`.

## 🛠 Step 3: Set your IP

```bash
curl -s https://checkip.amazonaws.com
```

Open `vars.yml` and set `my_ip_cidr` to that address plus `/32`, for example `203.0.113.25/32`. The playbook stops
with a clear message if you forget.

## 🛠 Step 4: Create and configure the instance

`create-ec2.yml` has **two plays**. The first runs on your machine and talks to the AWS API:

```yaml
- name: Look up the latest Amazon Linux 2023 AMI
  ansible.builtin.set_fact:
    ami_id: "{{ lookup('amazon.aws.ssm_parameter', ami_ssm_parameter, region=aws_region) }}"

- name: Create an SSH key pair and save the private key
  amazon.aws.ec2_key:
    name: "{{ key_name }}"
    region: "{{ aws_region }}"
    file_name: "{{ key_file }}"

- name: Create a security group that allows SSH from your IP only
  amazon.aws.ec2_security_group:
    name: "{{ security_group_name }}"
    description: SSH access for Ansible Lab 09
    region: "{{ aws_region }}"
    rules:
      - proto: tcp
        ports: [22]
        cidr_ip: "{{ my_ip_cidr }}"

- name: Launch the instance
  amazon.aws.ec2_instance:
    name: "{{ instance_name }}"
    region: "{{ aws_region }}"
    image_id: "{{ ami_id }}"
    instance_type: "{{ instance_type }}"
    key_name: "{{ key_name }}"
    security_group: "{{ security_group_name }}"
    tags: "{{ common_tags }}"
    state: running
    wait: true
  register: ec2

- name: Add the instance to an in-memory inventory group
  ansible.builtin.add_host:
    name: "{{ ec2.instances[0].public_ip_address }}"
    groups: lab09_servers
    ansible_user: ec2-user
    ansible_ssh_private_key_file: "{{ key_file }}"
```

The second play connects to the new server over SSH:

```yaml
- name: Configure the new instance
  hosts: lab09_servers
  become: true
  tasks:
    - name: Wait until SSH works (new instances take a minute to boot)
      ansible.builtin.wait_for_connection:
        timeout: 300
    - name: Set a login message
      ansible.builtin.copy:
        dest: /etc/motd
        content: "Provisioned and configured by Ansible (Lab 09)\n"
```

Run it (it takes 2–3 minutes):

```bash
ansible-playbook create-ec2.yml
```

```text
TASK [Show the new instance]
    msg: i-0abc123... is running at 54.x.x.x
...
TASK [Show what we connected to]
    msg: Amazon 2023, 916 MB RAM
```

Log in and see the message Ansible set:

```bash
ssh -i ~/.ssh/lab09-key.pem ec2-user@<PUBLIC_IP>
```

## 🛠 Step 5: Run it again

```bash
ansible-playbook create-ec2.yml
```

No second instance is created: `ec2_instance` finds the existing one by its `Name` tag. Cloud modules are
idempotent too.

## 🛠 Step 6: Clean up (don't skip this!)

```bash
ansible-playbook terminate-ec2.yml
```

It terminates the instance, then deletes the security group, the key pair and your local `.pem` file. Double-check
nothing is still running:

```bash
aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=ansible-labs" "Name=instance-state-name,Values=running" \
  --query "Reservations[].Instances[].InstanceId"
```

`[]` means you're clean.

## 🧪 Try it yourself

1. Add `user_data` to the instance to install nginx on first boot.
2. Use `exact_count: 2` (with `filters` on the Name tag) to run two identical instances.
3. In the second play, install `htop` with `ansible.builtin.dnf`.

## 🔍 Verify

- `ssh` to the instance shows "Provisioned and configured by Ansible (Lab 09)"
- After Step 6, the `describe-instances` check returns `[]`

➡️ **Next:** [Lab 10: Ansible with Kubernetes](../lab10-ansible-with-kubernetes/)
