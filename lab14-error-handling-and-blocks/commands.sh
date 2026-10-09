#!/usr/bin/env bash
# Lab 14: Error handling and blocks. Run from this folder. No sudo needed.
cd ~/Ansible-Labs/lab14-error-handling-and-blocks

# block / rescue / always
ansible-playbook resilient-deploy.yml                            # health check fails -> rollback to 1.0
cat /tmp/lab14/app/version.txt
ansible-playbook resilient-deploy.yml -e simulate_failure=false  # succeeds -> 2.0 is live
cat /tmp/lab14/app/version.txt

# The other tools: assert, ignore_errors, failed_when, retries/until
ansible-playbook error-controls.yml
ansible-playbook error-controls.yml -e disk_usage_limit=150      # assert stops the play
ansible-playbook error-controls.yml -e disk_usage_limit=1        # failed_when trips on disk usage

# Bonus: start a web server on 8099 in another terminal, then the retry task succeeds:
#   python3 -m http.server 8099
# (it returns 404 for /health; change the URL to / to see a 200)

# Clean up
rm -rf /tmp/lab14
