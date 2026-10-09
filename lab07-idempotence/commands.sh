#!/usr/bin/env bash
# Lab 07: Idempotence. Run from this folder. No sudo needed.
cd ~/Ansible-Labs/lab07-idempotence

# The wrong way: run it three times and watch the file grow
ansible-playbook not_idempotent.yml
ansible-playbook not_idempotent.yml
ansible-playbook not_idempotent.yml
cat /tmp/lab07_bad.conf

# The right way: run it twice; the second run should say changed=0
ansible-playbook idempotent_core.yml
ansible-playbook idempotent_core.yml
cat /tmp/lab07_good.conf

# Prove it automatically: fail if the second run changes anything
ansible-playbook idempotent_core.yml | tee /tmp/lab07_run.log
grep -q "changed=0" /tmp/lab07_run.log && echo "IDEMPOTENT ✅" || echo "NOT IDEMPOTENT ❌"

# Drift: change the file by hand, then let Ansible put it back
sed -i 's/log_level=info/log_level=trace/' /tmp/lab07_good.conf
ansible-playbook idempotent_core.yml --check --diff
ansible-playbook idempotent_core.yml

# Clean up
rm -rf /tmp/lab07_bad.conf /tmp/lab07_bad_dir /tmp/lab07_good.conf /tmp/lab07_good_dir /tmp/lab07_backup.tar.gz /tmp/lab07_run.log
