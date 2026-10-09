# Lab 06: Troubleshooting

| Problem | Why it happens | Fix |
| --- | --- | --- |
| `Attempting to decrypt but no vault secrets found` | You ran a playbook that uses a vault file without giving a password. | Add `--ask-vault-pass` or `--vault-password-file ~/.vault_pass`. |
| `Decryption failed (no vault secrets were found that could decrypt)` | Wrong password, or the file was re-keyed. | Check the password file contents; try `ansible-vault view FILE --ask-vault-pass`. |
| `input is already encrypted` | You tried to encrypt the same file twice. | Use `ansible-vault edit` to change it instead. |
| `Could not find or access 'vault_files/database_secrets.yml'` | You haven't created it from the example yet. | Do Step 2. |
| Secrets appear in the output | The task doesn't have `no_log: true`, or you used `debug` on a secret. | Add `no_log: true` to tasks that handle secrets; never `debug` a password. |
| `ansible-vault edit` opens vi and you can't exit | The default editor is vi. | Press `Esc`, type `:wq`, Enter. Or use `EDITOR=nano ansible-vault edit FILE`. |
| You committed a plain-text secret by mistake | Git keeps history. | Rotate the secret immediately (change the real password). Deleting the file isn't enough. |
