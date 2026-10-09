# Lab 06: Interview questions

**1. What is Ansible Vault?**
A feature that encrypts files or single values with AES-256 so secrets can be stored in version control and
decrypted only at runtime.

**2. How do you give Ansible the vault password at runtime?**
`--ask-vault-pass`, `--vault-password-file PATH` (the file can also be a script that prints the password), or the
`ANSIBLE_VAULT_PASSWORD_FILE` environment variable / `vault_password_file` setting.

**3. What is the difference between encrypting a whole file and `encrypt_string`?**
File encryption hides the whole file, including variable names. `encrypt_string` encrypts one value, so the rest
of the file stays readable and reviewable.

**4. What are vault IDs?**
Labels that let you use several vault passwords in one run, for example `--vault-id dev@prompt --vault-id
prod@~/.prod_pass`.

**5. What does `no_log: true` do?**
It hides a task's arguments and results from the output and logs, so secrets don't leak even when a task fails.

**6. How would you manage vault passwords in a CI/CD pipeline?**
Store the password as a pipeline secret (Jenkins credentials, GitHub Actions secrets) and write it to a temporary
file or pass it through a script given to `--vault-password-file`.

**7. Is Vault a replacement for HashiCorp Vault or AWS Secrets Manager?**
No. Ansible Vault encrypts files at rest in your repo. Secret managers provide central storage, access policies,
auditing and rotation. Ansible can read from them with lookup plugins.

**8. You leaked a password into a Git commit. What do you do?**
Rotate the secret first, then remove it from history (for example with `git filter-repo`) and encrypt it with
Vault going forward.

**9. What does `ansible-vault rekey` do?**
It re-encrypts a vault file with a new password without exposing the plain text.

**10. Does `ansible-vault view` write the decrypted content to disk?**
No. `view` and `edit` work in memory or with secure temporary files; only `decrypt` writes plain text to disk.
