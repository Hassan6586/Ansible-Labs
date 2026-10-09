# Lab 20: Multi-cloud inventories

Cloud servers come and go. Writing their IPs into `inventory.ini` by hand doesn't scale: the file is out of
date the moment someone launches or terminates an instance. **Inventory plugins** ask the cloud provider
"what's running right now?" every time Ansible starts, and build the groups for you.

In this final lab you combine **three sources** into one inventory:

```text
inventories/
├── 01-onprem.yml        # static: your own data centre (works offline)
├── 50-aws_ec2.yml       # dynamic: EC2 instances, read live from AWS
└── 99-constructed.yml   # groups hosts from ALL sources by provider and environment
optional/
└── azure_rm.yml         # dynamic: Azure VMs (copy into inventories/ to use)
```

## 🎯 What you'll learn

- Using a **folder** as an inventory, and why file names start with numbers
- The `amazon.aws.aws_ec2` inventory plugin: `filters`, `hostnames`, `keyed_groups`, `groups`, `compose`
- The `ansible.builtin.constructed` plugin to group hosts across clouds
- Giving every source the **same variable names** so one playbook works everywhere
- (Optional) the same idea for Azure with `azure.azcollection.azure_rm`

## 🧠 Key ideas in plain words

| Option | What it does | Example |
| --- | --- | --- |
| `plugin:` | Which inventory plugin reads this file | `amazon.aws.aws_ec2` |
| `filters:` | Only include matching instances | running, tagged `ManagedBy=ansible` |
| `hostnames:` | What to call each host | the `Name` tag |
| `keyed_groups:` | Make a group from each value of a field | `Environment=lab` → group `env_lab` |
| `groups:` | Put hosts in a group when a condition is true | `aws: true` |
| `compose:` | Create host variables from instance data | `ansible_host: public_ip_address` |

> 💡 Inventory plugins need a specific file name ending: `aws_ec2.yml`, `azure_rm.yml`, `gcp_compute.yml`.
> `50-aws_ec2.yml` works; `aws.yml` doesn't.

## ✅ Before you start

```bash
cd ~/Ansible-Labs/lab20-multi-cloud-inventories
source ~/ansible-cloud-venv/bin/activate        # from Lab 09 (has boto3)
ansible-galaxy collection install -r requirements.yml
```

Steps 1 and 2 work offline. Step 3 needs the AWS credentials from Lab 09 and, ideally, the instance from
Lab 09 running (`ansible-playbook ../lab09-aws-ec2-provisioning/create-ec2.yml`).

## 🛠 Step 1: The static part and the constructed groups

`inventories/01-onprem.yml` is a normal YAML inventory. Each host has the variables we want **every** source
to have: `cloud_provider`, `env`, `region` and `instance_size`.

```yaml
onprem:
  vars:
    ansible_connection: local
    cloud_provider: onprem
    region: karachi-dc1
  hosts:
    onprem-db1:
      env: production
      instance_size: large
    onprem-app1:
      env: staging
      instance_size: medium
```

`inventories/99-constructed.yml` makes groups from those variables, for hosts from **any** source:

```yaml
plugin: ansible.builtin.constructed
strict: false
keyed_groups:
  - key: cloud_provider
    prefix: provider
  - key: env
    prefix: env
groups:
  production: env == 'production'
  cloud: cloud_provider in ['aws', 'azure']
```

It's called `99-...` because inventory files load in alphabetical order, and `constructed` can only group
hosts that are already loaded.

Try just these two files:

```bash
ansible-inventory -i inventories/01-onprem.yml -i inventories/99-constructed.yml --graph
```

```text
@all:
  |--@ungrouped:
  |--@onprem:
  |  |--onprem-db1
  |  |--onprem-app1
  |--@production:
  |  |--onprem-db1
  |--@provider_onprem:
  |  |--onprem-db1
  |  |--onprem-app1
  |--@env_production:
  |  |--onprem-db1
  |--@env_staging:
  |  |--onprem-app1
```

The `production`, `provider_onprem` and `env_*` groups weren't written anywhere: `constructed` made them.

## 🛠 Step 2: Read the AWS plugin file

`inventories/50-aws_ec2.yml`:

```yaml
plugin: amazon.aws.aws_ec2
regions:
  - us-east-1
filters:
  instance-state-name: running
  tag:ManagedBy: ansible           # only instances Ansible created (Lab 09 tags them)
hostnames:
  - tag:Name                       # call the host "lab09-instance", not "ec2-54-1-2-3..."
  - instance-id
groups:
  aws: true
keyed_groups:
  - key: ec2_tags.Environment      # Environment=lab -> group env_lab
    prefix: env
  - key: instance_type             # t3.micro -> group type_t3_micro
    prefix: type
  - key: placement.region
    prefix: aws_region
compose:
  ansible_host: public_ip_address | default(private_ip_address)
  ansible_user: "'ec2-user'"       # the quotes inside the quotes make it a fixed text value
  cloud_provider: "'aws'"
  env: ec2_tags.Environment | default('none')
  region: placement.region
  instance_size: instance_type
```

The `compose` section is the important trick: it gives AWS hosts the **same variable names** as the on-prem
hosts, so `constructed` and your playbooks treat them all the same way.

## 🛠 Step 3: The whole multi-cloud inventory

`ansible.cfg` points at the folder, so every file is loaded:

```ini
[defaults]
inventory = inventories/
```

Check you're logged in to AWS, then build the inventory:

```bash
aws sts get-caller-identity
ansible-inventory --graph
```

With the Lab 09 instance and one more tagged `Environment=production` running, you'll see:

```text
@all:
  |--@ungrouped:
  |--@onprem:
  |  |--onprem-db1
  |  |--onprem-app1
  |--@aws_ec2:
  |  |--aws-web-prod
  |  |--lab09-instance
  |--@aws:
  |  |--aws-web-prod
  |  |--lab09-instance
  |--@env_production:
  |  |--aws-web-prod
  |  |--onprem-db1
  |--@type_t3_micro:
  |  |--lab09-instance
  |--@aws_region_us_east_1:
  |  |--aws-web-prod
  |  |--lab09-instance
  |--@env_lab:
  |  |--lab09-instance
  |--@production:
  |  |--onprem-db1
  |  |--aws-web-prod
  |--@provider_onprem:
  |  |--onprem-db1
  |  |--onprem-app1
  |--@provider_aws:
  |  |--aws-web-prod
  |  |--lab09-instance
  ...
```

Look at `env_production`: one on-prem server and one EC2 instance, in the same group. 🎉

See what Ansible knows about one EC2 host:

```bash
ansible-inventory --host lab09-instance | grep -E '"(ansible_host|ansible_user|cloud_provider|env|region|instance_size)"'
```

```text
    "ansible_host": "54.214.113.85",
    "ansible_user": "ec2-user",
    "cloud_provider": "aws",
    "env": "lab",
    "instance_size": "t3.micro",
    "region": "us-east-1",
```

> ℹ️ **No AWS account or credentials?** You'll see a few `Failed to parse ... 50-aws_ec2.yml` warnings and the
> AWS hosts are simply missing. The rest of the inventory still works.

## 🛠 Step 4: One playbook, every cloud

`show-inventory.yml` describes every host, then targets `env_production`, a group that mixes sources:

```bash
ansible-playbook show-inventory.yml
```

```text
TASK [Describe each host]
ok: [onprem-db1] =>
    msg: 'onprem-db1: provider=onprem, env=production, region=karachi-dc1, size=large'
ok: [onprem-app1] =>
    msg: 'onprem-app1: provider=onprem, env=staging, region=karachi-dc1, size=medium'
ok: [aws-web-prod] =>
    msg: 'aws-web-prod: provider=aws, env=production, region=us-east-1, size=t3.small'
ok: [lab09-instance] =>
    msg: 'lab09-instance: provider=aws, env=lab, region=us-east-1, size=t3.micro'

PLAY [Target a group that mixes sources]
ok: [aws-web-prod] =>
    msg: aws-web-prod is production (aws)
ok: [onprem-db1] =>
    msg: onprem-db1 is production (onprem)
```

`debug` runs on your own machine, so this playbook never logs in to the instances. To actually connect, use
the key from Lab 09:

```bash
ansible aws -m ansible.builtin.ping --private-key ~/.ssh/lab09-key.pem
```

## 🛠 Step 5 (optional): Add Azure

The Azure plugin works the same way, with slightly different option names (`conditional_groups`,
`hostvar_expressions`). Read `optional/azure_rm.yml`, then:

```bash
ansible-galaxy collection install azure.azcollection
pip install -r ~/.ansible/collections/ansible_collections/azure/azcollection/requirements.txt
az login
cp optional/azure_rm.yml inventories/60-azure_rm.yml
ansible-inventory --graph
```

Azure VMs show up in `azure`, `provider_azure` and the same `env_*` groups as everything else. Google Cloud
(`google.cloud.gcp_compute`) follows the same pattern too.

## 🧪 Try it yourself

1. Add a `keyed_groups` entry for the `Project` tag, so Lab 09's instance joins `project_ansible_labs`.
2. Remove the `tag:ManagedBy` filter. Which instances appear now?
3. Make `ansible_host` use `private_ip_address` only (what you'd do with a VPN or bastion host).
4. Add `cache: true` and `cache_plugin: ansible.builtin.jsonfile` (with `cache_connection: /tmp/aws-inv`) to
   the AWS file, and compare how long `ansible-inventory --graph` takes the second time.
5. Write a playbook with `hosts: provider_aws:&env_lab` (AWS **and** lab). What other patterns can you think
   of?

## 🔍 Verify

```bash
ansible-inventory --graph env_production   # hosts from more than one source
ansible-inventory --list | python3 -m json.tool | head -40
```

## 🧹 Clean up

Nothing runs in this lab, so there's nothing to delete here. If you started EC2 instances for it, terminate
them so they don't cost money:

```bash
ansible-playbook ../lab09-aws-ec2-provisioning/terminate-ec2.yml
```

## 🏁 You finished all 20 labs

You went from `ansible --version` to multi-cloud inventories. Ideas for what's next:

- Put one of these labs in a real project at work or in your portfolio
- Learn **Molecule** to test your roles automatically
- Build a custom **execution environment** with `ansible-builder`
- Study for the **Red Hat Certified Engineer (RHCE, EX294)** exam

⬅️ **Back to the start:** [All labs](../README.md)
