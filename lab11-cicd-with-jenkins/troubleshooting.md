# Lab 11: Troubleshooting

| Problem | Why it happens | Fix |
| --- | --- | --- |
| `ansible: not found` in the Jenkins log | Ansible isn't on the `jenkins` user's PATH (for example installed with pipx for your user only). | Install it system-wide from the PPA, then `sudo -u jenkins ansible --version`. |
| `Unable to find Jenkinsfile` | Wrong **Script Path**. | Set it to `lab11-cicd-with-jenkins/Jenkinsfile` exactly. |
| `[WARNING]: No inventory was parsed` | Ansible ran outside the lab folder, so `ansible.cfg` wasn't used. | Keep the `dir(env.LAB_DIR)` wrapper around the commands. |
| `Ansible is being run in a world writable directory` | The workspace permissions are too open. | Fix the folder permissions, or pass `-i inventory/hosts.ini` explicitly. |
| `Destination directory ... does not exist` during the dry run | A task writes into a folder that only exists after a real run. | Guard it with `when: not ansible_check_mode` (as the playbook does). |
| `GIT_COMMIT` is empty | The job isn't "Pipeline script from SCM", so Jenkins didn't check out Git. | Use SCM mode; the Jenkinsfile already falls back to `unknown`. |
| `Permission denied` on `/var/lib/jenkins/webapp` when you look | The files belong to the `jenkins` user. | Use `sudo ls` / `sudo cat`. |
| Git checkout fails for a private repo | Jenkins has no credentials for GitHub. | Add a GitHub token under **Credentials** and select it in the job. |
