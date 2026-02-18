# Claude Code Rules

## Python

- Always place all `import` and `from ... import` statements at the **top of the file**, before any other code.
- Imports must be **sorted**: standard library first, then third-party, then local — each group sorted alphabetically within itself (isort order).
- Never use wildcard imports (`from module import *`). Always import only the names you need explicitly.
