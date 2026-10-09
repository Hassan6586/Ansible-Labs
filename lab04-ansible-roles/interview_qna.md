# Lab 04: Interview questions

**1. What is an Ansible role, and why use one?**
A standard folder structure that packages tasks, handlers, templates, files and variables for one job (such as
"web server"). Roles make automation reusable, testable and shareable.

**2. What is the difference between `defaults/` and `vars/` in a role?**
`defaults/` has the lowest priority of all variables, so users can easily override them. `vars/` has high
priority and is meant for values the role relies on internally.

**3. What is a handler?**
A task that runs only when notified by another task that reported `changed`. Handlers run once at the end of the
play, even if notified several times.

**4. How can you run handlers before the end of the play?**
Add `- ansible.builtin.meta: flush_handlers` as a task.

**5. What is the difference between `roles:` and `include_role` / `import_role`?**
`roles:` and `import_role` are static: they're processed when the playbook is parsed. `include_role` is dynamic:
it's processed at runtime, so it can be used with loops and conditions.

**6. What is Ansible Galaxy?**
A public hub (galaxy.ansible.com) for sharing roles and collections, and the `ansible-galaxy` CLI used to create,
install and publish them.

**7. How do you declare that one role depends on another?**
In the `dependencies:` list in `meta/main.yml`. Dependencies run before the role itself.

**8. What is the difference between the `copy` and `template` modules?**
`copy` copies a file as it is. `template` renders a Jinja2 file, filling in variables, before copying it.

**9. Why prefix role variables with the role name?**
All variables share one namespace, so a generic name like `port` in two roles would clash. `webserver_port` is
unambiguous.

**10. What is the difference between a role and a collection?**
A role is one unit of automation. A collection is a distribution package that can contain many roles plus modules,
plugins and playbooks (for example `amazon.aws`).
