# Lab 09: Interview questions

**1. Which collection manages AWS, and what does it need on the control node?**
`amazon.aws` (plus `community.aws` for extra services). It needs the boto3 and botocore Python libraries and AWS
credentials.

**2. How does Ansible find AWS credentials?**
The standard boto3 chain: environment variables (`AWS_ACCESS_KEY_ID`...), `~/.aws/credentials` and config profiles,
then instance or container roles. You can also pass `profile:` to modules.

**3. Why look up the AMI through SSM instead of hard-coding it?**
AMI IDs differ per region and change when images are updated. AWS publishes the latest IDs as public SSM
parameters, so the lookup always gets a current image.

**4. How do you provision a server and configure it in the same playbook?**
Create it in a first play, use `add_host` to put it in an in-memory group, then target that group in a second play,
starting with `wait_for_connection`.

**5. How is `ec2_instance` idempotent?**
It looks for existing instances matching the `name`/`filters` (tags) and only creates what's missing. `exact_count`
lets you scale to a precise number.

**6. Terraform vs Ansible for provisioning infrastructure?**
Terraform keeps state and plans changes, which suits creating and destroying infrastructure. Ansible is stronger
at configuring what runs on servers. Many teams use Terraform to build and Ansible to configure.

**7. Why tag cloud resources?**
To find, group, bill and clean them up. Tags also drive dynamic inventory groups (Lab 20).

**8. How would you avoid storing AWS keys on a CI server?**
Use IAM roles: an instance profile on EC2, IRSA or Pod Identity on EKS, or OIDC federation from GitHub Actions.

**9. What does `wait: true` on `ec2_instance` do?**
It makes the task wait until the instance reaches the requested state (for example `running`) before continuing.

**10. Why restrict SSH to `my_ip/32` instead of `0.0.0.0/0`?**
Port 22 open to the internet gets brute-force attempts within minutes. Limiting it to your IP greatly reduces the
attack surface.
