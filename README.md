# Agent companion for Apple Silicon

Keep local Codex and Claude sessions visible in a terminal panel. The companion
is compiled Zig code; it makes no model requests and never switches providers.

## Install

Requires Apple Silicon, macOS 13 or later, and Ghostty with AppleScript support.
Install Codex or Claude separately using their own account and setup instructions.

Download and run the installer:

```sh
curl -fL https://github.com/Carmezim/agent-companion-releases/releases/latest/download/install.sh -o /tmp/agent-companion-install.sh
bash /tmp/agent-companion-install.sh
```

No compiler, Python, GitHub account or source repository access is required.
The installer checks the archive checksum, runtime receipt and app signature.
Builds use a local ad hoc signature; they are not Apple notarized releases.

If `agents` is not found, add its directory to your shell configuration:

```sh
export PATH="$HOME/.local/bin:$PATH"
```

## Open a view

| Command | Behavior |
| --- | --- |
| `agents --panel` | Run inside the current terminal pane or tab. |
| `agents --floating` | Open a separate Ghostty TUI window above other windows. |
| `agents --workspace` | Keep the session list beside interactive agent terminals. |
| `agents --window` | Open the optional macOS app window. |
| `agents -h` | Show command instructions. |
| `agents -v` / `agents --version` | Show the installed version and build information. |

Panel and floating modes do not require tmux. Workspace mode requires
tmux 3.6 or later, installed locally:

```sh
brew install tmux
agents --workspace
```

In the workspace's left pane, type `:new codex` or `:new claude`, then Enter.
Use `:new --name 'Fix login' --cwd ~/src/app codex` to name it and choose a directory.
Provider arguments follow the provider name and remain literal. Enter or a click
opens the selected agent on the right. Click the list to return; merely moving
the highlight sends no input and changes no desktop focus.

The workspace owns a separate tmux server. Closing its views leaves agents
running; reopening reconnects. Existing sessions in ordinary tabs stay there.
Existing personal tmux configuration and servers remain separate.

## Track native sessions

Preview the native hook changes, then apply them:

```sh
terminal-workspace setup-hooks
terminal-workspace setup-hooks --apply
```

If the registered installation path changed, setup migrates its companion hooks
and existing status-line wrapper. Unrelated hooks and rendered output are preserved.
After a partial setup failure, rerun the same command to finish the migration.

Setup enables the Claude session observer by default so ordinary `claude`
launches register. It preserves your status line's output or runs silently when
you have no custom renderer, refreshing every five seconds to recover a missed
startup observation. Existing renderers keep their refresh settings.
After updating an older installation, rerun
`terminal-workspace setup-hooks --apply` once.

Start or resume native clients after setup so they load the hooks. Allow macOS
Automation access to Ghostty when prompted; the app reuses that grant. Answer
questions and permissions in the agent session, or use the panel's answer field
for supported root Codex async questions. Other requests retain `:open` to return
to the agent session. Acknowledging panel attention does not answer a question
or grant permission.

## Pi trial

Pi 1.2.0 is also supported for names, model/effort, activity and errors. Install
Pi separately, run `terminal-workspace setup-pi --apply`, then restart Pi or use
`/reload`. Use ordinary `pi` sessions with panel/floating mode, or `:new pi` in
workspace mode. Questions and child agents are not tracked yet.

## Controls

Use `j/k` or arrows to select and Enter to open. Tab or Shift+Tab switches
Sessions and Details; `h/j/k/l` or arrows move the Details cursor. `/` searches
sessions and `?` shows contextual help. `v` selects characters, `V` selects lines,
and `y` copies the highlighted range. Drag within Details and release to copy;
`:copy` copies the expanded Details document. In every terminal panel mode,
`:d` or `:remove` removes a session from the list; `:attach` / `:a` restores it.
In workspace, `:detach` disconnects its viewer; `:close`, then `:close!`, confirms
closing its selected agent terminal. Detached jobs may continue. Cmd+Option+Left/Right
focuses the panel/agent split. Workspace windows start with floating off.
`F` toggles floating for the containing Ghostty
window. `:q` closes the panel and leaves agents running.
Esc, then `:`, opens a visible command line. Enter runs it; Esc cancels it.
Plain `q` never closes the panel.

Optional PR tracking starts off. Type `:prs on` to enable it with your existing
GitHub CLI login, or `:prs off` to stop it. Codex checkout branch/commit matches
and supported native Claude links appear in Details. Checkout matches describe
Git relationships, not which agent owns the work; multiple matches stay visible.
Use `:pr URL` to choose an explicit session link. `:prs refresh 15s` saves a check
interval; `r` requests fresh checks, including after authenticating `gh` again.

For child details, type `:children`, then Enter; select a child and press Enter
again. `:requests` opens the current session's or opened child's request list.
In the request list, `:dismiss` hides an obsolete request locally; `:dismissed`
shows dismissed requests and Enter restores one. No answer or approval is sent.
Esc returns. In the child list, `:d` hides a child and `:attach` restores one.
`:clear-history` hides ended child turns; later turns appear again. Provider
logs and running processes stay intact.

## Files and updates

- Launchers: `~/.local/bin/agents` and `~/.local/bin/terminal-workspace`.
- Active version: `~/.local/share/agent-companion-current`.
- Versioned binaries: `~/.local/share/agent-companion-releases/`.
- Local session state: `~/.local/state/terminal-workspace/`.
- Workspace socket: `workspace.sock` in that state directory.

Run `agents --update` to install the latest public release. It verifies before
activation, preserves launchers, local state and the previous version directory,
and leaves running agents alone. Reopen your panel to use the new version.
Versions before 0.3.2 can update by running the installer again.

For a development build prepared on your own Mac, run `agents --update --local`.
This installs the latest prepared local package; it does not compile unfinished
source. Preparing a local build requires the private source checkout and its
developer tools, so beta testers normally use `agents --update`.

For a bug report, include what happened and the output of
`agents --diagnostics > agent-companion-report.json`. The file includes at most
128 recent action timings/error codes and 64 workspace observations (process IDs,
rendered row counts and errors), plus app version and platform. It excludes
session content and paths; nothing is uploaded automatically.

 No histories, credentials, private source or
test fixtures are included in public downloads. This repository distributes
binaries and user documentation; the implementation source is private.

The macOS 13 deployment target is compiled and inspected; older OS runtime
compatibility still needs testing on those OS versions.
