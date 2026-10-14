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

Workspace mode requires tmux 3.6 or later, installed locally:

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

Start or resume native clients after setup so they load the hooks. Allow macOS
Automation access to Ghostty when prompted; the app reuses that grant. Questions
and permissions are answered in the agent session. Acknowledging panel attention
does not answer a question or grant permission.

## Controls

Use `j/k` or arrows to select, Enter to open, `h/l` for list/details, `/` to search, and
`?` for all controls. Tab changes list/detail focus; `{` and `}` follow
that focus. `v` freezes mouse selection; Cmd+C copies in Ghostty. `V`, `j/k`, and
`y` select and copy detail lines. `:d` detaches a workspace viewer; `:close`,
then `:close!`, confirms closing its selected agent terminal. Detached jobs may
continue. Cmd+Option+Left/Right
focuses the panel/agent split. Workspace windows start with floating off.
`F` toggles floating for the containing Ghostty
window. `:q` closes the panel and leaves agents running.
Esc, then `:`, opens a visible command line. Enter runs it; Esc cancels it.
Plain `q` never closes the panel.

## Files and updates

- Launchers: `~/.local/bin/agents` and `~/.local/bin/terminal-workspace`.
- Active version: `~/.local/share/agent-companion-current`.
- Versioned binaries: `~/.local/share/agent-companion-releases/`.
- Local session state: `~/.local/state/terminal-workspace/`.
- Workspace socket: `workspace.sock` in that state directory.

Run the installer again to update. It verifies before activation and preserves
the previous version directory. No histories, credentials, private source or
test fixtures are included in public downloads. This repository distributes
binaries and user documentation; the implementation source is private.

The macOS 13 deployment target is compiled and inspected; older OS runtime
compatibility still needs testing on those OS versions.
