# Lab 17: Interview questions

**1. What is AWX, and how is it related to Ansible Tower and AAP?**
AWX is the open-source upstream project. Ansible Tower was Red Hat's supported product built from it; Tower is
now called Automation Controller and ships as part of Red Hat Ansible Automation Platform.

**2. Why use AWX instead of running `ansible-playbook` from a laptop?**
Central logs of every run, role-based access control, safely stored credentials, schedules, a REST API, surveys,
workflows and notifications. People can run automation without SSH keys or shell access.

**3. How is AWX installed today?**
With the AWX Operator on Kubernetes. You create an `AWX` custom resource and the operator deploys the web, task
and database pods.

**4. What is a Project in AWX?**
A source of playbooks, usually a Git repository. AWX syncs it before (or on a schedule) and lists the playbooks
it finds.

**5. What is a Job Template?**
A saved definition of a run: which playbook, which inventory, which credentials, extra variables, and options
such as limits, tags and verbosity.

**6. What is an execution environment?**
A container image with ansible-core, Python packages and collections. Every AWX job runs inside one, so runs are
reproducible. You build custom ones with `ansible-builder`.

**7. How do credentials stay secret in AWX?**
They're encrypted in the database and injected into the job at runtime (as files or environment variables).
Users can use a credential without being able to see it.

**8. What is a Workflow Template?**
A chain of job templates (and approvals or project syncs) with success/failure branches, for example "deploy →
test → if it fails, roll back".

**9. How can a CI/CD pipeline start an AWX job?**
Through the REST API (`POST /api/v2/job_templates/<id>/launch/`), the `awx` CLI, or the `awx.awx.job_launch`
module, using an OAuth token.

**10. How do you manage the AWX configuration itself as code?**
With the `awx.awx` collection (modules like `project`, `inventory`, `job_template`), so AWX objects are created
from playbooks stored in Git rather than by clicking.
