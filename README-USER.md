# README-USER

Simple instructions for using `agent-browser` inside any project.

## Quick setup

From an `agent-browser` checkout, run:

```bash
./scripts/setup-for-project.sh /path/to/your-project
```

By default this copies `agent-browser` into:

```text
/path/to/your-project/tools/agent-browser
```

The script:

- copies this repository into the target project
- reuses the current native binary when it is already present
- falls back to `pnpm install` if the copied checkout needs a binary
- tries to run `agent-browser install --with-deps` on Linux

## Run commands

Use the vendored CLI directly from your project:

```bash
cd /path/to/your-project
./tools/agent-browser/bin/agent-browser.js open https://example.com
./tools/agent-browser/bin/agent-browser.js snapshot -i
./tools/agent-browser/bin/agent-browser.js click @e1
./tools/agent-browser/bin/agent-browser.js close
```

## Linux note

On Linux, the setup script tries to install both Chrome for Testing and the system libraries it needs.

If that step fails because the machine has no package manager access, no `sudo`, or no network, rerun the install later from the copied checkout:

```bash
cd /path/to/your-project/tools/agent-browser
./bin/agent-browser.js install --with-deps
```

If Chrome or Chromium is already installed on the machine, `agent-browser` will usually detect it automatically.
