# Lab 14: Interview questions

**1. What are `block`, `rescue` and `always`?**
`block` groups tasks; `rescue` runs if any task in the block fails (like `except`); `always` runs regardless (like
`finally`).

**2. If a block fails and `rescue` succeeds, is the host marked as failed?**
No. The recap shows `rescued=1` and `failed=0`, and the play continues for that host.

**3. What does `ansible_failed_task` contain?**
The task that failed (its name, action, arguments) inside a `rescue` section; `ansible_failed_result` holds its
result.

**4. `ignore_errors` vs `failed_when`?**
`ignore_errors` accepts any failure. `failed_when` defines precisely what failure means, which is safer because real
problems still fail.

**5. How do you wait for a service to become available?**
`retries` + `until` + `delay` on a check task (`uri`, `command`), or the `wait_for` module for ports and files.

**6. What does `any_errors_fatal` do?**
If any host fails, the whole play stops on all hosts, which is useful when hosts depend on each other (clusters).

**7. What is `max_fail_percentage`?**
A play setting: abort the play if more than that percentage of hosts in a batch fail, often used with `serial`.

**8. Why do extra vars need `| bool`?**
`-e key=value` passes strings; the string "false" is truthy. The `bool` filter converts it properly.

**9. How would you implement an automatic rollback for a deployment?**
Back up or keep the previous release, deploy inside a `block`, run health checks in the block, and restore the
previous version in `rescue`.

**10. What's the difference between `rescue` and handlers?**
`rescue` reacts to failures inside a block. Handlers react to changes (`notify`) and run at the end of a play.
