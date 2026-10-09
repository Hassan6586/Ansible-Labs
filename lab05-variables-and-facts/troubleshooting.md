# Lab 05: Troubleshooting

| Problem | Why it happens | Fix |
| --- | --- | --- |
| `'db_host' is undefined` | The variable isn't set anywhere for this host. | Define it, or give a fallback: `{{ db_host \| default('localhost') }}`. |
| `[WARNING]: conditional statements should not include jinja2 templating delimiters` | You wrote `when: "{{ x }} == 1"`. | Remove the braces: `when: x == 1`. |
| `'dict object' has no attribute 'stdout'` | The registered task was skipped, or it's a module that doesn't return `stdout`. | Print the whole variable with `debug: var=name` to see what it contains. |
| `'ansible_facts' is undefined` or facts are empty | The play has `gather_facts: false`. | Set `gather_facts: true`, or run `ansible.builtin.setup` as a task. |
| Comparing numbers fails (`'>' not supported between 'str' and 'int'`) | The value came in as text (common with `-e`). | Convert it: `{{ value \| int }}`. |
| A `group_vars` value is ignored | A higher-priority source (play vars, `-e`) sets the same name. | Check where else the name is defined; `-e` always wins. |
| YAML error on a value starting with `{{` | YAML reads `{` as the start of a dictionary. | Quote it: `msg: "{{ value }}"`. |
