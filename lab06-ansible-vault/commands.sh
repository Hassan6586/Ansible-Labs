#!/usr/bin/env bash
# Lab 06: Ansible Vault. Run from this folder. No sudo needed.
cd ~/Ansible-Labs/lab06-ansible-vault

# 1. A vault password file (outside the repo, readable only by you)
echo "MyLabVaultPassword123" > ~/.vault_pass
chmod 600 ~/.vault_pass

# 2. Create the secrets file from the example, then encrypt it
cp vault_files/database_secrets.example.yml vault_files/database_secrets.yml
ansible-vault encrypt vault_files/database_secrets.yml --vault-password-file ~/.vault_pass
head -3 vault_files/database_secrets.yml          # unreadable now

# 3. Read and edit it safely
ansible-vault view vault_files/database_secrets.yml --vault-password-file ~/.vault_pass
EDITOR=nano ansible-vault edit vault_files/database_secrets.yml --vault-password-file ~/.vault_pass

# 4. Use it in a playbook
ansible-playbook database_setup.yml --vault-password-file ~/.vault_pass
ansible-playbook database_setup.yml --ask-vault-pass
ls -l /tmp/lab06-secure_config.conf

# 5. Change the vault password
echo "MyNewVaultPassword456" > ~/.vault_pass_new && chmod 600 ~/.vault_pass_new
ansible-vault rekey vault_files/database_secrets.yml --vault-password-file ~/.vault_pass --new-vault-password-file ~/.vault_pass_new
mv ~/.vault_pass_new ~/.vault_pass

# 6. Encrypt a single value
ansible-vault encrypt_string 'SuperSecretSMTP!' --name smtp_password --vault-password-file ~/.vault_pass

# Clean up
rm -f /tmp/lab06-secure_config.conf vault_files/database_secrets.yml
