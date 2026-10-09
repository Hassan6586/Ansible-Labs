# Lab 20: Interview questions

**1. What is a dynamic inventory?**
An inventory built at runtime from an external source (a cloud API, a CMDB, a virtualisation platform) instead
of a hand-written file, so it always matches what actually exists.

**2. What's the difference between an inventory script and an inventory plugin?**
Scripts are any executable that prints JSON (`--list`, `--host`). Plugins are the modern way: configured with a
YAML file, support caching, `compose`, `keyed_groups` and `groups`, and ship in collections.

**3. How does Ansible know a YAML file is a plugin config?**
The `auto` plugin reads the `plugin:` key and hands the file to that plugin. Most cloud plugins also require
a specific file name ending, such as `aws_ec2.yml`.

**4. What do `keyed_groups`, `groups` and `compose` do?**
`keyed_groups` makes one group per value of a field (one per environment tag). `groups` adds hosts to a group
when a condition is true. `compose` creates or overrides host variables with Jinja expressions.

**5. How do you combine several inventory sources?**
Point `-i` (or `inventory =` in `ansible.cfg`) at a folder, or pass `-i` several times. Sources are merged;
files in a folder load in alphabetical order.

**6. What does the `constructed` plugin do?**
It creates groups and variables from variables that already exist, across every source loaded before it. It
makes no API calls.

**7. How do you limit which EC2 instances appear?**
`filters` (any EC2 `DescribeInstances` filter, e.g. state or tags), `include_filters` / `exclude_filters`, and
`regions`.

**8. How would you speed up a large dynamic inventory?**
Enable the inventory cache (`cache: true`, a `cache_plugin` and `cache_timeout`), restrict regions and filters,
and only fetch what you need.

**9. How do you connect to instances without public IPs?**
`compose: ansible_host: private_ip_address`, and connect through a bastion (`ProxyJump`), a VPN, or the AWS SSM
connection plugin.

**10. Why give every source the same variable names?**
So playbooks, templates and `constructed` groups work the same regardless of where a host lives. The cloud
becomes an implementation detail, not something every playbook has to know about.
