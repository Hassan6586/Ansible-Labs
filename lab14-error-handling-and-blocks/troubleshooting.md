# Lab 14: Troubleshooting

| Problem | Why it happens | Fix |
| --- | --- | --- |
| `-e simulate_failure=false` still fails | Extra vars from `key=value` are text, and `"false"` is truthy. | Use `\| bool`, or pass JSON: `-e '{"simulate_failure": false}'`. |
| `rescue` never runs | The failing task isn't inside the `block:`, or the error is a syntax/templating error found before the run. | Indent the task under `block:`; fix syntax errors first (`--syntax-check`). |
| `'ansible_failed_task' is undefined` | Used outside a `rescue` section. | It only exists inside `rescue`. |
| `until` never succeeds though the service is up | The condition checks the wrong field. | `debug: var=health` to see the real structure. |
| `retries` seems ignored | `until` is missing; `retries` does nothing without it. | Always use `retries` together with `until`. |
| `failed_when` with an `int` comparison errors | The value is text like `"34%"`. | Clean it first: `\| trim \| replace('%','') \| int`. |
| `ignore_errors` hid a real problem | It ignores **every** failure of that task. | Prefer a precise `failed_when`. |
