# Lab 15: Interview questions

**1. What is the difference between the `copy` and `template` modules?**
`copy` transfers a file as it is. `template` renders a Jinja2 file on the control node (filling in variables,
loops and conditions) and then copies the result to the host.

**2. Where is a template rendered: on the control node or the managed host?**
On the control node. Only the finished file is sent to the host, so the host doesn't need Jinja2 installed.

**3. What are the three Jinja2 delimiters?**
`{{ }}` prints an expression, `{% %}` runs a statement (`if`, `for`, `set`), and `{# #}` is a comment that
doesn't appear in the output.

**4. How do you avoid an error when a variable might not be defined?**
Use the `default` filter: `{{ port | default(8080) }}`. Use `default(omit)` in module arguments to leave the
option out completely.

**5. What is `ansible_managed`?**
A string (set in `ansible.cfg`) you put at the top of a template, usually as a comment, to warn people that
manual edits will be overwritten.

**6. How do you preview a template change without applying it?**
`ansible-playbook site.yml --check --diff`. The template module shows a unified diff of what would change.

**7. How do you check a generated config before it replaces the live one?**
The `validate` option runs a command on the temporary file first, for example
`validate: /usr/sbin/nginx -t -c %s` or `validate: visudo -cf %s`. If it fails, the file isn't replaced.

**8. How do you output literal `{{ }}` (for example, a Helm chart) from a template?**
Wrap it in `{% raw %} ... {% endraw %}`.

**9. What does whitespace control (`{%-` and `-%}`) do?**
The dash removes whitespace and newlines before or after the tag, so loops and conditions don't leave blank
lines in the output.

**10. Name some filters you use often.**
`default`, `join`, `length`, `upper`/`lower`, `map`, `selectattr`/`rejectattr`, `dict2items`/`items2dict`,
`to_nice_json`/`to_nice_yaml`, `int`/`bool`, `regex_replace`, `combine` and `unique`.
