# Lab 19: Interview questions

**1. What is hybrid cloud automation?**
Managing on-premises and public cloud resources with the same tools and code. With Ansible: one inventory
with groups per environment and the same playbooks for both.

**2. How do you handle settings that differ per environment?**
Use the same variable names in `group_vars/<group>.yml` for each environment. Playbooks and templates stay the
same; only the data changes.

**3. What is `hostvars`?**
A dictionary of every host's variables. `hostvars['db1']['private_ip']` lets one host use another host's data.

**4. What does `groups` contain?**
Every group name mapped to the list of hosts in it, for example `groups['cloud']`.

**5. What does `delegate_to` do?**
Runs a task on a different host than the one being processed, for example opening a firewall on the database
server for each web server, or removing a server from a load balancer.

**6. What is `run_once`?**
The task runs only once for the whole batch of hosts instead of once per host. Useful for reports, database
migrations or API calls.

**7. What's the difference between `--limit` and `hosts:`?**
`hosts:` in the play sets which hosts it's for; `--limit` narrows that down for one run. Other hosts are still
in the inventory, so `hostvars` and `delegate_to` can use them.

**8. Explain group variable precedence.**
`all` is lowest, then parent groups, then child groups, then host variables. Groups at the same level merge
alphabetically unless `ansible_group_priority` is set. Extra vars (`-e`) beat everything.

**9. How do you connect to cloud servers that have no public IP?**
Through a bastion host (`ansible_ssh_common_args: '-o ProxyJump=user@bastion'`), a VPN, or AWS SSM
(`amazon.aws.aws_ssm` connection plugin).

**10. How would you make the cloud part of this inventory dynamic?**
Use an inventory plugin such as `amazon.aws.aws_ec2` or `azure.azcollection.azure_rm`, and combine it with the
static on-prem file in one inventory folder. That's Lab 20.
