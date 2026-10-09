#!/usr/bin/env bash
# Lab 15: Jinja2 templates. Run from this folder. No sudo needed.
cd ~/Ansible-Labs/lab15-jinja2-templates

# Render all four templates into /tmp/lab15
ansible-playbook render-templates.yml
cat /tmp/lab15/app.conf
cat /tmp/lab15/nginx-upstream.conf
cat /tmp/lab15/features.json
cat /tmp/lab15/report.txt

# Run again: changed=0 (templates are idempotent)
ansible-playbook render-templates.yml

# Preview production without writing anything
ansible-playbook render-templates.yml -e environment_name=production --check --diff

# Play with filters
ansible-playbook filters-playground.yml

# Verify
python3 -m json.tool /tmp/lab15/features.json

# Clean up
rm -rf /tmp/lab15
