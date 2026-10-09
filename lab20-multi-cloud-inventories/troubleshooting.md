# Lab 20: Troubleshooting

| Problem | Why it happens | Fix |
| --- | --- | --- |
| `Failed to import the required Python library (botocore and boto3)` | Ansible isn't running from the virtual environment. | `source ~/ansible-cloud-venv/bin/activate`. |
| `Unable to locate credentials` / `NoCredentialsError` | AWS credentials aren't set up. | `aws configure` (Lab 09), then `aws sts get-caller-identity`. |
| `Failed to parse ... 50-aws_ec2.yml` warnings, but the rest works | The AWS source failed (no credentials or no internet). Other sources still load. | Fix the AWS error, or run with `-i inventories/01-onprem.yml -i inventories/99-constructed.yml`. |
| The AWS file is read as a normal YAML inventory | The file name doesn't end in `aws_ec2.yml`. | Rename it, e.g. `50-aws_ec2.yml`. |
| No EC2 hosts appear, and no errors | The `filters` exclude them (stopped, wrong region, missing `ManagedBy` tag). | Remove filters one at a time; check the region. |
| Hosts are named like `ec2-54-1-2-3.compute-1.amazonaws.com` | They have no `Name` tag. | Tag them, or keep `instance-id` as the fallback in `hostnames`. |
| `constructed` groups miss the AWS hosts | `constructed` ran before the AWS file. | Files load alphabetically: keep `99-` on the constructed file. |
| `compose: ansible_user: ec2-user` gives an error or empty value | `compose` values are Jinja expressions, so `ec2-user` is read as a variable. | Quote the text inside: `"'ec2-user'"`. |
| `DEPRECATION WARNING: The 'tags' host variable is deprecated` | The `amazon.aws` collection warns about its old `tags` variable, even though this lab uses `ec2_tags`. | Harmless. It disappears once the collection drops `tags`; you can hide it with `deprecation_warnings = False`. |
| `ec2_tags` is undefined | Your `amazon.aws` is older than 11.2. | `ansible-galaxy collection install amazon.aws --upgrade`. |
| SSH to EC2 fails | Wrong user, key, or the security group doesn't allow your IP. | Amazon Linux uses `ec2-user`, Ubuntu uses `ubuntu`; check the key and the Lab 09 security group. |
| Inventory is slow with many instances | Every run calls the AWS API. | Turn on the inventory cache (`cache: true`). |
