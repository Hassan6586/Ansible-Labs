# Lab 09: Troubleshooting

| Problem | Why it happens | Fix |
| --- | --- | --- |
| `Failed to import the required Python library (botocore or boto3)` or `boto3 >= 1.35.0 required` | Modules run with a Python that lacks a recent boto3. | Activate the virtual environment (`source ~/ansible-cloud-venv/bin/activate`) and run from this folder so `inventory.ini` is used. |
| `Unable to locate credentials` / `NoCredentialsError` | AWS credentials aren't configured. | `aws configure`, then `aws sts get-caller-identity`. |
| `UnauthorizedOperation` | Your IAM user lacks EC2 permissions. | Attach a policy such as `AmazonEC2FullAccess` (for the lab), or ask your admin. |
| `Set my_ip_cidr in vars.yml` | The assert caught the placeholder. | Put your IP from `curl -s https://checkip.amazonaws.com` in `vars.yml` as `x.x.x.x/32`. |
| `InvalidKeyPair.Duplicate` or the `.pem` file is missing | The key exists in AWS but you lost the local file. | Run `terminate-ec2.yml`, which deletes the key in AWS, then create again. |
| `wait_for_connection` times out | Security group doesn't allow your IP (your IP changed?), or the instance has no public IP. | Re-check your IP and `vars.yml`. Use a default VPC subnet that assigns public IPs. |
| `Permissions 0644 for 'lab09-key.pem' are too open` | SSH refuses keys others can read. | `chmod 600 ~/.ssh/lab09-key.pem` |
| `InstanceLimitExceeded` / `VcpuLimitExceeded` | Your account's limit is reached. | Terminate unused instances or request a quota increase. |
| The free tier doesn't cover `t3.micro` in your account | Free-tier rules depend on account age and region. | Check the Billing console; `t3.micro` costs about $0.01/hour. |
