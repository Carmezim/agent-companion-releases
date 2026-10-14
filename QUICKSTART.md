# Agent companion beta

- **Install:** run the terminal installer below. Apple Silicon Mac, macOS 13+.
- **Enable tracking:** run `terminal-workspace setup-hooks --apply`, then restart
  Codex/Claude sessions when convenient so they load the hooks.
- **Open:** `agents --floating` keeps the panel visible while you switch sessions.
  Use `agents --panel` to run it in your current terminal pane instead.
- **Move and open:** arrows or `j` / `k` select; Enter opens the agent.
- **Find:** `/` searches. Enter keeps the search; Esc clears it.
- **Read details:** `l` or Right opens details; `h` or Left returns to the list.
  `{` / `}` jumps between sections. `x` expands extra context; `H` shows child history.
- **Copy:** `y` copies details. `v` freezes the display for mouse selection and Cmd+C;
  Esc resumes updates.
- **Remove / restore:** `:d` removes a session from the panel without stopping it.
  `:attach` (or `:a`) lists other running sessions; Enter adds one.
- **Quit:** press Esc, type `:q`, then Enter. Your agents keep running.
- **Help:** `?` lists controls; `agents -h` shows command-line options.
- **Update:** `agents --update`. Reopen the panel to load the new version.
- **Report a bug:** describe what you did and what happened; include the output of
  `agents --diagnostics > agent-companion-report.json`. It contains recent timings
  and error codes, without session names, directories, prompts or answers.

```sh
curl -fsSL https://github.com/Carmezim/agent-companion-releases/releases/latest/download/install.sh -o /tmp/agent-companion-install.sh
bash /tmp/agent-companion-install.sh
```

If `agents` is not found, add `~/.local/bin` to your shell's PATH.

Workspace mode is optional: install tmux 3.6+ (`brew install tmux`), then run
`agents --workspace`. Use `:new codex` or `:new claude` to start sessions inside
that workspace. Cmd+Option+Left/Right moves between the list and agent terminal.
Here `:d` disconnects the viewer, Enter reconnects, and `:close` followed by
`:close!` closes the selected agent terminal. Panel and floating modes do not
require tmux.

Green means working, red means an error or interruption, purple means review is
requested. An **unknown outcome** means a request was seen but its answer or
cancellation was not; it may already be resolved. Answer questions in the agent's
own session.
