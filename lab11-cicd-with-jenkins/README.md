# Lab 11: CI/CD pipelines with Jenkins and Ansible

In real teams nobody runs `ansible-playbook` by hand for production. A **CI/CD pipeline** runs it on every change:
check the code, do a dry run, deploy, then verify. Here Jenkins does that with a playbook that deploys each build
into its own release folder, so a rollback is instant.

## 🎯 What you'll learn

- Writing a declarative `Jenkinsfile` that calls Ansible
- Passing build information (`BUILD_NUMBER`, `GIT_COMMIT`) into a playbook with `-e`
- The **releases + current symlink** deployment pattern, and how to roll back
- Making the pipeline fail when verification fails (`assert`)
- Handling check mode for tasks that depend on earlier changes

## 🧠 Key ideas in plain words

| Term | What it means |
| --- | --- |
| **CI/CD** | Continuous Integration / Continuous Delivery: every change is checked and deployed automatically. |
| **Jenkinsfile** | The pipeline written as code and stored in the repo, next to what it deploys. |
| **Stage** | One step of the pipeline (Syntax check → Dry run → Deploy → Verify). If one fails, the rest don't run. |
| **Release folder** | Each build gets `releases/<build>`. The `current` symlink points to the live one. |
| **`ansible_check_mode`** | A variable that's `true` during `--check`, used to skip tasks that can't work in a dry run. |

## ✅ Before you start

- Ansible installed system-wide from the PPA (Lab 01), so the `jenkins` user can run it
- Jenkins installed. If you did the [Jenkins labs](https://github.com/Hassan6586/Jenkins-Labs) you already have it;
  otherwise follow the official guide: <https://www.jenkins.io/doc/book/installing/linux/#debianubuntu>
- This repository pushed to **your own** GitHub account (so Jenkins can check it out)

```text
lab11-cicd-with-jenkins/
├── Jenkinsfile                  # the pipeline
├── ansible.cfg
├── inventory/hosts.ini          # group "web" = localhost
└── playbooks/
    ├── deploy-webapp.yml        # the deployment
    └── templates/
        ├── index.html.j2
        └── version.txt.j2
```

## 🛠 Step 1: Run the deployment by hand

Always make a playbook work locally before you put it in a pipeline.

```bash
cd ~/Ansible-Labs/lab11-cicd-with-jenkins
ansible-playbook playbooks/deploy-webapp.yml --syntax-check
ansible-playbook playbooks/deploy-webapp.yml --check --diff -e build_number=1
```

Now pretend four builds happen:

```bash
ansible-playbook playbooks/deploy-webapp.yml -e build_number=1 -e git_commit=abc1234
ansible-playbook playbooks/deploy-webapp.yml -e build_number=2 -e git_commit=def5678
ansible-playbook playbooks/deploy-webapp.yml -e build_number=3 -e git_commit=0a1b2c3
ansible-playbook playbooks/deploy-webapp.yml -e build_number=4 -e git_commit=9f8e7d6
```

```text
TASK [Fail the pipeline if the wrong build is live]
    msg: Build 4 is live
```

```bash
ls ~/webapp/releases            # 2  3  4   (keep_releases: 3)
readlink ~/webapp/current       # /home/you/webapp/releases/4
cat ~/webapp/current/version.txt
```

**Rollback** is just moving the symlink:

```bash
ln -sfn ~/webapp/releases/3 ~/webapp/current
cat ~/webapp/current/version.txt        # build=3
rm -rf ~/webapp                         # reset before Jenkins runs
```

### How the playbook works

```yaml
vars:
  app_root: "{{ lookup('ansible.builtin.env', 'HOME') }}/webapp"
  build_number: manual          # Jenkins overrides with -e build_number=$BUILD_NUMBER
  keep_releases: 3
  release_dir: "{{ app_root }}/releases/{{ build_number }}"

tasks:
  - name: Create the release folder            # releases/<build>
  - name: Render the app files into the release folder
  - name: Point "current" at the new release   # the symlink switch = the deploy
  - name: Delete old releases (keep the newest 3)
  - name: Fail the pipeline if the wrong build is live   # assert
```

Two tasks have `when: not ansible_check_mode`: during a dry run the release folder isn't really created, so
writing files into it or reading them back would fail.

## 🛠 Step 2: Let the jenkins user run Ansible

```bash
sudo -u jenkins ansible --version
```

If that fails, install Ansible from the PPA (Lab 01, Step 1). The playbook needs **no sudo**: it deploys into the
`jenkins` user's home (`/var/lib/jenkins/webapp`).

## 🛠 Step 3: Create the pipeline job

1. Push this repository to your GitHub account (or fork it).
2. In Jenkins: **New Item** → name `ansible-lab11` → **Pipeline** → OK.
3. Under **Pipeline**: Definition **Pipeline script from SCM** → SCM **Git** → your repository URL → branch
   `*/main`.
4. **Script Path**: `lab11-cicd-with-jenkins/Jenkinsfile`
5. Save, then **Build Now**.

The `Jenkinsfile`:

```groovy
pipeline {
    agent any
    environment { LAB_DIR = 'lab11-cicd-with-jenkins' }

    stages {
        stage('Check tools')  { steps { sh 'ansible --version' } }
        stage('Syntax check') { steps { dir(env.LAB_DIR) {
            sh 'ansible-playbook playbooks/deploy-webapp.yml --syntax-check' } } }
        stage('Dry run')      { steps { dir(env.LAB_DIR) {
            sh 'ansible-playbook playbooks/deploy-webapp.yml --check --diff -e build_number=$BUILD_NUMBER -e git_commit=${GIT_COMMIT:-unknown}' } } }
        stage('Deploy')       { steps { dir(env.LAB_DIR) {
            sh 'ansible-playbook playbooks/deploy-webapp.yml -e build_number=$BUILD_NUMBER -e git_commit=${GIT_COMMIT:-unknown}' } } }
        stage('Verify')       { steps { sh 'cat "$HOME/webapp/current/version.txt"' } }
    }
}
```

(The file in the folder is the same, laid out over more lines, plus `options` and `post` sections.)

> 💡 The commands are in **single quotes**, so the **shell** expands `$BUILD_NUMBER`, not Groovy. That's the safe
> habit: Groovy string interpolation of secrets can leak them into logs.

## 🛠 Step 4: Watch it work

Open the build → **Stage View** (or **Console Output**). Every stage turns green, and the last one prints:

```text
app=lab11-webapp
build=1
commit=3f2a9c1...
```

Click **Build Now** four more times, then check that only three releases are kept:

```bash
sudo ls /var/lib/jenkins/webapp/releases
```

## 🧪 Try it yourself

1. Break `deploy-webapp.yml` (remove a colon), push, and watch the pipeline stop at **Syntax check**.
2. Add a **Lint** stage that runs `ansible-lint playbooks/` (install it with `pipx install ansible-lint`).
3. Add an `input` step before **Deploy** so a human must approve production deployments.
4. Add a GitHub webhook so every push triggers a build automatically.

## 🔍 Verify

`sudo cat /var/lib/jenkins/webapp/current/version.txt` shows the latest Jenkins build number.

## 🧹 Clean up

```bash
rm -rf ~/webapp
sudo rm -rf /var/lib/jenkins/webapp
```

Delete the `ansible-lab11` job in Jenkins if you don't need it.

➡️ **Next:** [Lab 12: Multi-tier application](../lab12-multi-tier-application/)
