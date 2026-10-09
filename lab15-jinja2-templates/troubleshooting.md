# Lab 15: Troubleshooting

| Problem | Why it happens | Fix |
| --- | --- | --- |
| `'db_host' is undefined` | The template uses a variable that isn't set anywhere. | Define it, or use `{{ db_host \| default('localhost') }}`. |
| `No filter named 'ljust'` (or similar) | Not every Python string method is a Jinja2 filter. | Use `{{ '%-6s' \| format(name) }}`, or check the [filter list](https://docs.ansible.com/ansible/latest/collections/index_filter.html). |
| `Could not find or access 'app.conf.j2'` | The `src` path is wrong. | Put templates in a `templates/` folder next to the playbook (or inside the role) and use just the file name. |
| Empty lines everywhere in the output | Each `{% %}` line leaves its newline behind. | Use `{%- ... -%}` to trim whitespace, or set `trim_blocks` (on by default in Ansible). |
| `debug = False` instead of `false` | Python prints booleans with a capital letter. | Use `{{ debug_mode \| lower }}` or `{{ debug_mode \| to_json }}`. |
| JSON file is invalid | A hand-written JSON template forgot a comma or quote. | Build a dict and use `to_nice_json`; add `validate: python3 -m json.tool %s`. |
| `{{ }}` from another tool (Helm, Go) gets eaten | Ansible tries to render it as Jinja2. | Wrap that part in `{% raw %} ... {% endraw %}`. |
| A task always reports `changed` | A value like a timestamp (`ansible_date_time`) changes every run. | Don't put the current time in a template unless you really want that. |
| `-e debug_mode=false` turns debug on | Extra vars from the command line are text, and `"false"` is truthy. | Use `\| bool` in conditions: `{% if debug_mode \| bool %}`. |
