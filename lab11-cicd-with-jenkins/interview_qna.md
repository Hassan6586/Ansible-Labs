# Lab 11: Interview questions

**1. How do you run Ansible from Jenkins?**
In a pipeline stage with `sh 'ansible-playbook ...'` (or the Ansible plugin), passing build data like
`-e build_number=$BUILD_NUMBER`. The agent needs Ansible installed and access to the inventory and credentials.

**2. What stages would you put in an Ansible deployment pipeline?**
Lint (`ansible-lint`) → syntax check → dry run (`--check --diff`) → optional manual approval → deploy → verify
(smoke tests) → notify.

**3. How do you pass secrets (vault password, SSH keys) to Ansible in Jenkins?**
Store them as Jenkins credentials and use `withCredentials` to expose them as temporary files or environment
variables, for example `--vault-password-file $VAULT_PASS_FILE`.

**4. What is the "releases + current symlink" pattern?**
Each deploy goes into a new versioned folder; switching a symlink makes it live. It gives atomic switches, quick
rollbacks and easy cleanup of old releases.

**5. How would you roll back?**
Point `current` back at the previous release (or re-run the pipeline for an older build number).

**6. Why single quotes around `sh` commands in a Jenkinsfile?**
So the shell, not Groovy, expands variables. Groovy interpolation of secret values can leak them into logs and is
flagged by Jenkins.

**7. What does `ansible_check_mode` let you do?**
Detect a dry run and skip or adjust tasks that can't work without real changes.

**8. How do you make a pipeline fail when the deployment is wrong?**
Use `assert` or `uri` checks with conditions; a failed task returns a non-zero exit code, which fails the stage.

**9. What does `disableConcurrentBuilds()` prevent?**
Two builds deploying at the same time and racing to switch the same symlink.

**10. How could GitHub Actions replace Jenkins here?**
A workflow with the same steps: check out, install Ansible, run the playbook with `-e build_number=${{ github.run_number }}`,
using repository secrets for credentials.
