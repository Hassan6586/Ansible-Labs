#!/usr/bin/env bash
# Lab 09: Provisioning AWS EC2. Creates real (small) AWS resources: run terminate-ec2.yml when done!
cd ~/Ansible-Labs/lab09-aws-ec2-provisioning

# 1. Python virtual environment with Ansible + the AWS SDK (reused in Labs 10, 18 and 20)
sudo apt install -y python3-venv
python3 -m venv ~/ansible-cloud-venv
source ~/ansible-cloud-venv/bin/activate
pip install --upgrade pip
pip install ansible boto3 botocore
ansible --version
ansible-galaxy collection install -r requirements.yml

# 2. AWS CLI and credentials
sudo snap install aws-cli --classic
aws configure                       # access key, secret key, region us-east-1, output json
aws sts get-caller-identity         # proves the credentials work

# 3. Your public IP, for the security group
curl -s https://checkip.amazonaws.com
# edit vars.yml: my_ip_cidr: "x.x.x.x/32"

# 4. Create and configure the instance
ansible-playbook create-ec2.yml
ssh -i ~/.ssh/lab09-key.pem ec2-user@<PUBLIC_IP>

# 5. Re-run: nothing new is created
ansible-playbook create-ec2.yml

# 6. Clean up (IMPORTANT: stops charges)
ansible-playbook terminate-ec2.yml
aws ec2 describe-instances --filters "Name=tag:Project,Values=ansible-labs" "Name=instance-state-name,Values=running" --query "Reservations[].Instances[].InstanceId"
