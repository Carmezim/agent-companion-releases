# Agent Companion beta quick start

Agent Companion shows local Codex, Claude and Pi sessions in one terminal panel.
It reads native harness data and makes no model requests. You do not need
agent-workflow, custom agent instructions, Python or a compiler.

## Upgrade from 0.4.0 or later

Run in your normal terminal:

```sh
agents --update
agents --version
```

Close and reopen the panel to load the new version. Your agents keep running.
Existing tracking settings and preferences stay in place.

- Pi users: run `/reload` inside **each open Pi session** after updating.
- If tracking already works, keep your hook setup. If you never enabled it,
  or a harness is missing, follow the matching setup below.
- If you run a background monitor, restart it with `agents serve --stop`,
  then `agents serve --background`. A monitor started with plain
  `agents serve` still stops with Ctrl+C in its own terminal.

The bottom-right panel version identifies the code it is running.
`agents --version` identifies the installed code; an already-open panel can
still be running the previous version.

## First installation

Requires an Apple Silicon Mac with macOS 13 or later. Install your harnesses
separately. Download and run the public installer:

```sh
curl -fsSL https://github.com/Carmezim/agent-companion-releases/releases/latest/download/install.sh -o /tmp/agent-companion-install.sh
bash /tmp/agent-companion-install.sh
```

If your shell cannot find `agents`, add `~/.local/bin` to your PATH.

## Enable tracking for your harnesses

For Codex and Claude:

```sh
terminal-workspace setup-hooks --apply
```

Restart and resume those sessions when convenient so they load the hooks.
Ordinary launches are supported; you do not need to start agents through
Companion. Claude's observer preserves an existing status line and stays silent
when there is no custom renderer.

For Pi:

```sh
terminal-workspace setup-pi --apply
```

Run `/reload` inside each open Pi session, or restart Pi. Pi supplies names,
model, reasoning, activity and failures. Questions and child agents are not
tracked yet. Setup **without `--apply` only previews changes**.

Native names take precedence. Unnamed sessions use their native ID when
available; Pi's `/name` command gives a session a name.

## Open the panel

```sh
agents --panel
```

For a floating view:

```sh
agents --floating
```

In Rex, the overlay follows tabs within its session. Click it to use its keys.
`F` docks the panel; pressing `F` again floats it. Docked or minimized panels
stay in their tab. Ghostty opens a separate floating window.

For Rex navigation, enable **Settings → Rex Server → Remote Control** in the
local Rex app. This lets Companion ask the app to display the selected terminal.
The panel reports refused requests and destinations it cannot verify.

- Arrows or `j/k` select a session; Enter opens a supported terminal.
- Tab switches Sessions and Details. Enter expands the item under the cursor.
- `1`–`4` filter All, Needs you, Working and To review. `:show-all` clears filters.
- `/` searches; `r` refreshes; `?` opens help.
- In Details, drag and release to copy, or use `v` / `V`, movement keys, then `y`.
- Click the footer message or run `:messages` to read and copy recent errors.
  Use `y` to copy the message history, or select a range first. Esc returns.
- `:q` closes only the panel. Your agents keep running.

Panel and floating modes need no tmux. The optional `agents --workspace` mode
requires tmux 3.6+ and keeps a list beside agent terminals.

## Shared session monitoring

The **session monitor**, also called the collector, is a separate local Zig
process. It checks sessions once and shares observations with compatible panels
and agent queries. It does not run models or answer questions.

Opening a panel starts or reuses it automatically. It exits after one minute
without readers. No setup command is needed for this. Workspace mode keeps its
own checks.

To keep the monitor running for tools even after panels close:

```sh
agents serve --background
agents serve --status
```

You can close that terminal. Repeating the start command keeps the existing
monitor and makes an automatic monitor persistent when the configuration matches.
It does not start at login or restart after a reboot.

```sh
agents serve --stop
```

Stopping it leaves agents running; panels resume their own checks. Plain
`agents serve` remains available in the foreground, stopped with Ctrl+C.
An open panel does not restart a stopped monitor. Reopening the panel tries
startup again. If startup fails, the panel keeps checking sessions directly.
The monitor and panels must use the same home, `PATH`, harness settings and
registry. Start a persistent monitor from the same shell you use for the panel;
an agent's command environment may have a different `PATH`.
The panel header shows **SHARED MONITOR** or **LOCAL CHECKS**. If it shows
**LOCAL · SETTINGS DIFFER**, `:messages` explains the mismatch. A running
`agents serve --status` alone does not establish that a panel can share its data.
If you override `TERMINAL_WORKSPACE_STATE`, use the same value for both.

Agent-facing reads are optional too:

```sh
agents sessions --json
agents wait attention --timeout 1m --json
agents socket
```

These read observations; they do not send answers or control agents.
`agents sessions --help` explains the agent workflow with a diagram, the JSON
fields, exit codes, and how to avoid repeated alerts for already-seen requests.
Sandboxed agents may need permission for the exact path printed by
`agents socket`. Companion does not change harness sandbox permissions.
You do not need that permission setup just to use the panel.

## Optional: PR checks and Claude answers

In the panel, `:prs on` enables PR checks through your existing GitHub CLI login.
`:prs refresh 15s` sets the interval; `r` also refreshes PRs.
`:pr URL` links one explicitly; `:prs off` disables checks.
Merged PRs stop automatic rechecking.

For future Claude questions to appear as answerable panel dialogs:

```sh
terminal-workspace setup-hooks --claude-questions panel --apply
```

Restart or resume Claude with a panel open. The panel collects choices or written
answers one question at a time, then shows the full batch before submission.
Existing dialogs and permission approvals stay in
Claude. To restore native answering:

```sh
terminal-workspace setup-hooks --claude-questions native --apply
```

Codex panel answers need a registered session, a verified native connection and
an active supported question. The panel explains when you must answer in Codex
instead. Once the originating turn has ended, open Codex to send a follow-up.
Pi questions use Pi. Dismissing attention never answers a question or grants permission.

## If something is missing

Press `r`, then `:show-all` to clear filters. Check the setup above and reload
or resume the affected harness. A terminal title can label a row without proving
which native conversation it controls; some rows cannot offer answers or PR association.

Send a screenshot and these outputs with your terminal app/version, harness
version, and what you expected to see:

```sh
agents --version
agents --doctor
agents serve --status
agents --diagnostics > agent-companion-report.json
```

The report contains timings, error codes, process IDs and counts. It excludes
session names, paths, prompts and answers. A stopped optional monitor does not
prevent the panel from working.
