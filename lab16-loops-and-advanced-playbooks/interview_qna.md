# Lab 16: Interview questions

**1. What is the difference between `loop` and `with_items`?**
Both repeat a task. `loop` is the modern, recommended keyword (Ansible 2.5+). `with_items` flattens nested
lists automatically; with `loop` you add `| flatten` yourself.

**2. How do you loop over a dictionary?**
`loop: "{{ my_dict | dict2items }}"`, then use `item.key` and `item.value`.

**3. What can you set in `loop_control`?**
`label` (what's printed), `index_var` (the counter), `loop_var` (rename `item`), `pause` (seconds between
items) and `extended` (adds `ansible_loop.first`, `.last`, `.length` and more).

**4. What happens when you `register` a variable on a loop?**
The variable gets a `results` list with one entry per item. Each entry includes the `item` it ran for.

**5. How do you write a nested loop?**
Use the `product` filter: `loop: "{{ list_a | product(list_b) | list }}"`, then `item.0` and `item.1`.
For more complex cases, loop over an `include_tasks` that has its own loop.

**6. How do you repeat a task until it succeeds?**
`until: <condition>` with `retries` and `delay`. The task runs again until the condition is true or the
retries run out.

**7. What is the difference between `include_tasks` and `import_tasks`?**
`import_tasks` is static (processed before the play runs). `include_tasks` is dynamic (processed while the play
runs), so it works with `loop` and variable file names.

**8. Can you use `loop` with `import_tasks`?**
No. Static imports are resolved before any variables exist. Use `include_tasks`.

**9. What are tags used for?**
To run (`--tags`) or skip (`--skip-tags`) part of a playbook. Special tags: `always` (runs unless skipped
explicitly) and `never` (runs only when asked for).

**10. How do you see what a playbook would run without running it?**
`--list-tasks`, `--list-tags` and `--list-hosts`. For a dry run that shows changes, use `--check --diff`.
