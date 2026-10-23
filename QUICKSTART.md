# Agent companion beta

- **Install:** run the terminal installer below. Apple Silicon Mac, macOS 13+.
- **Enable tracking:** run `terminal-workspace setup-hooks --apply`, then restart
  and resume Codex/Claude sessions when convenient so they load the hooks.
  Ordinary `claude` launches register through the installed status line observer.
  Existing status line output is preserved; without a custom renderer, the
  observer runs silently and retries idle observations every five seconds.
  After updating from an older version, rerun setup once.
- **Pi trial:** with Pi 1.2.0 installed, run `terminal-workspace setup-pi --apply`,
  then `/reload` in Pi. Names, model, activity and errors are tracked; questions
  and child agents are not included yet. Workspace can start it with `:new pi`.
- **Open:** `agents --floating` keeps the panel visible while you switch sessions.
  Use `agents --panel` to run it in your current terminal pane instead.
- **Move and open:** `j` / `k` or arrows select; Enter opens the agent.
- **Find:** `/` searches. Enter keeps the search; Esc clears it.
- **Read details:** Tab or Shift+Tab switches Sessions and Details. Use `h/j/k/l` or arrows to move the visible cursor; `{` / `}` jumps sections. Enter expands
  a group, answers a question, or inspects a request or child. Current work and
  pending input start open; earlier requests, saved context and session metadata
  start collapsed.
- **Questions:** Enter on a question opens its answer field for supported Codex
  async requests. Choose with `j/k` or arrows; Enter sends. **Write an answer**
  opens text input; Enter sends, Esc goes back, Ctrl+G opens field help. `:requests`
  lists requests; `:open` answers unsupported requests in the agent session.
  `:answered` or `:cancelled` clears a record already handled there without sending input.
- **PR tracking:** `:prs on` enables checks; `:prs off` stops them.
  `:prs refresh 15s` saves the interval without enabling tracking. `r` refreshes
  observations and requests fresh PR checks when enabled.
  Codex checkout branch/commit matches appear automatically through your existing
  `gh` login. `:pr URL` chooses an explicit session link instead.
- **Reviewed:** after reading completed output, `:reviewed` clears its review
  marker. It leaves unanswered questions and errors alone.
- **Copy:** `v` selects characters; `V` selects lines. Extend with arrows or Vim
  keys, then `y` copies. Drag within Details and release to copy immediately.
  `:copy` copies all expanded Details, including offscreen text. The highlight
  stays until Esc, an ordinary click, or a pane/session change. Details says
  **PAUSED** during selection; the session list and background tracking continue.
- **Remove / restore:** `:d` (or `:remove`) removes a session from the list in any
  mode without stopping it.
  `:attach` (or `:a`) lists other running sessions; Enter adds one.
- **Quit:** press Esc, type `:q`, then Enter. Your agents keep running.
- **Help:** `?` lists controls; `agents -h` shows command-line options.
- **Update:** `agents --update`. Reopen the panel to load the new version.
- **Version:** `agents -v` or `agents --version` shows the installed build.
- **Local development build:** `agents --update --local` installs the latest
  package prepared on your Mac, without a version or checkout path.
- **Report a bug:** describe what you did and what happened; include the output of
  `agents --diagnostics > agent-companion-report.json`. It contains recent timings
  and error codes, plus workspace process IDs and row counts. It excludes session
  names, directories, prompts and answers.

```sh
curl -fsSL https://github.com/Carmezim/agent-companion-releases/releases/latest/download/install.sh -o /tmp/agent-companion-install.sh
bash /tmp/agent-companion-install.sh
```

If `agents` is not found, add `~/.local/bin` to your shell's PATH.

Workspace mode is optional: install tmux 3.6+ (`brew install tmux`), then run
`agents --workspace`. Use `:new codex` or `:new claude` to start sessions inside
that workspace. Cmd+Option+Left/Right moves between the list and agent terminal.
Here `:detach` disconnects the viewer, Enter reconnects, and `:close` followed by
`:close!` closes the selected agent terminal. Panel and floating modes do not
require tmux.

### Where the displayed information comes from

The companion uses local processes and the harnesses' existing events. It makes
no model calls and needs no special agent reporting instructions. It can show
native final assistant text, Claude task updates and Pi completed responses.
Codex plan updates are supported when that hook is emitted; delivery remains
unverified for the installed localhost test client. Live commentary is not
captured yet, so a working agent can have an older description. Each description
keeps its source and original age; text from an earlier turn is labelled.

`agent-workflow` is Adriano's separate personal task-record helper. It is not a
Codex feature or a requirement for beta testers, and the installer does not copy
his instructions or task files. Saved task context and explicit progress reports
are optional extras; beta testers can use the panel without them.

Green means working, red means an error or interruption, purple means review is
requested. An **unknown outcome** means a request was seen but its answer or
cancellation was not; it may already be resolved. `:open` answers unsupported
requests in their agent session.

An open panel checks native Codex history for matching answers when a callback
was missed. This clears supported captured questions automatically. Older records
without the original question identity can still show an unknown outcome.
