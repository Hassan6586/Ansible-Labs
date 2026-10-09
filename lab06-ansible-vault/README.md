# Lab 06: Protecting secrets with Ansible Vault

Passwords, API tokens and private keys must never sit in Git as plain text. **Ansible Vault** encrypts them with
AES-256, so you can commit the encrypted file safely and Ansible decrypts it in memory when the playbook runs.

## 🎯 What you'll learn

- Encrypting, viewing, editing and re-keying a vault file
- Using encrypted variables in a playbook
- Encrypting a single value with `encrypt_string`
- Hiding secrets from output with `no_log: true`
- Keeping the vault password out of Git

## 🧠 Key ideas in plain words

| Command | What it does |
| --- | --- |
| `ansible-vault encrypt FILE` | Encrypts an existing plain file |
| `ansible-vault create FILE` | Creates a new encrypted file in your editor |
| `ansible-vault view FILE` | Shows the decrypted content without saving it to disk |
| `ansible-vault edit FILE` | Opens the decrypted content in your editor, then re-encrypts it |
| `ansible-vault rekey FILE` | Changes the vault password |
| `ansible-vault encrypt_string` | Encrypts one value you can paste into any YAML file |
| `ansible-vault decrypt FILE` | Turns it back into plain text on disk (**avoid this**) |

## ✅ Before you start

```bash
cd ~/Ansible-Labs/lab06-ansible-vault
```

## 🛠 Step 1: Create a vault password file

Typing the password every time gets tedious, so store it in a file that only you can read, **outside** the repo:

```bash
echo "MyLabVaultPassword123" > ~/.vault_pass
chmod 600 ~/.vault_pass
```

> ⚠️ In real projects the vault password comes from a password manager or a CI/CD secret, never from Git. This
> lab's `.gitignore` already blocks `.vault_pass` files.

## 🛠 Step 2: Encrypt a secrets file

Copy the example and encrypt it:

```bash
cp vault_files/database_secrets.example.yml vault_files/database_secrets.yml
ansible-vault encrypt vault_files/database_secrets.yml --vault-password-file ~/.vault_pass
head -3 vault_files/database_secrets.yml
```

The content is now unreadable:

```text
$ANSIBLE_VAULT;1.1;AES256
65363637366361353165616335616262626561653363346461316266313035646463393465666663
...
```

> 💡 You can also create an encrypted file directly with `ansible-vault create FILE`, which opens your editor.

## 🛠 Step 3: View and edit it safely

```bash
ansible-vault view vault_files/database_secrets.yml --vault-password-file ~/.vault_pass
EDITOR=nano ansible-vault edit vault_files/database_secrets.yml --vault-password-file ~/.vault_pass
```

`view` and `edit` never leave a decrypted copy on disk.

## 🛠 Step 4: Use the secrets in a playbook

`database_setup.yml`:

```yaml
- name: Use secrets from Ansible Vault
  hosts: local
  gather_facts: false

  vars_files:
    - vault_files/database_secrets.yml

  tasks:
    - name: Show that we can read the username (never print passwords!)
      ansible.builtin.debug:
        msg: "Connecting to the database as {{ db_username }}"

    - name: Write a config file that only the owner can read
      ansible.builtin.copy:
        dest: /tmp/lab06-secure_config.conf
        mode: "0600"
        content: |
          DB_USER={{ db_username }}
          DB_PASS={{ db_password }}
          API_TOKEN={{ api_token }}
      no_log: true
```

```bash
ansible-playbook database_setup.yml --vault-password-file ~/.vault_pass
# or type the password instead:
ansible-playbook database_setup.yml --ask-vault-pass
```

```text
TASK [Show that we can read the username (never print passwords!)]
    msg: Connecting to the database as admin_user
TASK [Write a config file that only the owner can read]
changed: [localhost]
```

Without `no_log: true`, a failure or `-v` would print the file content, including the password, into your
terminal and CI logs.

```bash
ls -l /tmp/lab06-secure_config.conf     # -rw------- : only you can read it
```

## 🛠 Step 5: Change the vault password (rekey)

```bash
echo "MyNewVaultPassword456" > ~/.vault_pass_new && chmod 600 ~/.vault_pass_new
ansible-vault rekey vault_files/database_secrets.yml \
  --vault-password-file ~/.vault_pass --new-vault-password-file ~/.vault_pass_new
mv ~/.vault_pass_new ~/.vault_pass
```

## 🛠 Step 6: Encrypt just one value

Sometimes you only need one secret inside an otherwise normal file:

```bash
ansible-vault encrypt_string 'SuperSecretSMTP!' --name smtp_password --vault-password-file ~/.vault_pass
```

```text
smtp_password: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          30643837653962343261613632623064376438626464613131363835623663303363353632626436
          ...
```

Paste that block into `encrypt_string_demo.yml` in place of the placeholder line, then run:

```bash
ansible-playbook encrypt_string_demo.yml --vault-password-file ~/.vault_pass
```

```text
    msg: smtp_password has 16 characters
```

## 🧪 Try it yourself

1. Add `redis_password` to the vault file with `ansible-vault edit` and use it in the playbook.
2. Run the playbook with a wrong password and read the error.
3. Remove `no_log: true`, run with `-v`, and notice what would have leaked.

## 🔍 Verify

- `head -1 vault_files/database_secrets.yml` prints `$ANSIBLE_VAULT;1.1;AES256`
- `/tmp/lab06-secure_config.conf` exists with permissions `-rw-------`

## 🧹 Clean up

```bash
rm -f /tmp/lab06-secure_config.conf vault_files/database_secrets.yml
```

Keep `~/.vault_pass` if you want to keep practising.

➡️ **Next:** [Lab 07: Idempotence](../lab07-idempotence/)
