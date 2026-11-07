#!/bin/bash
# Public binary installer. No compiler, provider requests or GitHub login required.
set -euo pipefail
umask 077
if [[ -n "${AGENT_COMPANION_HOME:-}" ]]; then
  printf 'Unset AGENT_COMPANION_HOME before installing the active release.\n' >&2
  exit 1
fi
directory=
runtime_only=0
for argument in "$@"; do
  case "$argument" in
    --runtime-only) [[ $runtime_only -eq 0 ]] || exit 2; runtime_only=1 ;;
    --from-directory=*) [[ -z "$directory" ]] || exit 2; directory="${argument#*=}" ;;
    *) printf 'Usage: bash install.sh [--from-directory=/ABSOLUTE/RELEASE_DIRECTORY] [--runtime-only]\n' >&2; exit 2 ;;
  esac
done
if [[ "$(/usr/bin/uname -s)" != Darwin || "$(/usr/bin/uname -m)" != arm64 ]]; then
  printf 'This release requires Apple Silicon macOS 13 or later.\n' >&2
  exit 1
fi
major="$(/usr/bin/sw_vers -productVersion)"
if [[ "${major%%.*}" -lt 13 ]]; then
  printf 'macOS 13 or later is required.\n' >&2
  exit 1
fi
data_root="${XDG_DATA_HOME:-${HOME:+$HOME/.local/share}}"
bin_root="$HOME/.local/bin"
releases="$data_root/agent-companion-releases"
current="$data_root/agent-companion-current"
for path in "$data_root" "$bin_root" "$releases"; do
  if [[ -L "$path" || ( -e "$path" && ! -d "$path" ) ]]; then
    printf 'Expected an owned directory: %s\n' "$path" >&2; exit 1
  fi
  mkdir -p "$path"
  if [[ ! -O "$path" ]]; then printf 'Directory is not owned by you: %s\n' "$path" >&2; exit 1; fi
done
install_lock="$data_root/.agent-companion-install.lock"
if [[ -d "$install_lock" && ! -L "$install_lock" ]]; then
  printf 'A legacy installation lock remains at %s. Once no installer is running, remove that empty directory with rmdir and retry.\n' "$install_lock" >&2
  exit 1
fi
if [[ -L "$install_lock" || ( -e "$install_lock" && ( ! -f "$install_lock" || ! -O "$install_lock" ) ) ]]; then
  printf 'Invalid installation lock: %s\n' "$install_lock" >&2; exit 1
fi
# Keep the open description in this shell. The helper borrows it; it must never
# issue LOCK_UN, which would also release the shell's lock. A killed installer
# can leave the empty file, but not a lock after its last descriptor closes.
exec 9<>"$install_lock"
installation_lock() {
  /usr/bin/perl -MFcntl=:flock,:mode -e '
    my ($operation, $path) = @ARGV;
    my @opened = stat(STDIN);
    sub valid {
      my ($info) = @_;
      return @$info && S_ISREG($info->[2]) && $info->[3] == 1 &&
        $info->[4] == $> && $info->[7] == 0 && !($info->[2] & 0022);
    }
    die "Invalid installation lock: $path\n" unless valid(\@opened);
    if ($operation eq "acquire") {
      unless (flock(STDIN, LOCK_EX | LOCK_NB)) {
        exit 75 if $!{EWOULDBLOCK} || $!{EAGAIN};
        die "Cannot lock $path: $!\n";
      }
    }
    # An opener can retain the old inode while the previous owner removes its
    # name. Do not install or unlink unless this locked descriptor still names it.
    my @named = lstat($path);
    die "Installation lock changed; retry: $path\n" unless valid(\@named) &&
      $opened[0] == $named[0] && $opened[1] == $named[1];
    unlink($path) or die "Cannot remove installation lock: $!\n" if $operation eq "release";
  ' "$1" "$install_lock" <&9
}
if installation_lock acquire; then :; else
  result=$?
  if [[ $result -eq 75 ]]; then printf 'Another installation is running; retry after it finishes.\n' >&2; fi
  exit 1
fi
# A signal to Bash can leave its foreground child alive. Keep its lock name and
# staging files: rollback, deletion or unlinking could race that child's work.
# The next installer can reuse this regular file after the last descriptor closes.
interrupted_installation() {
  trap - EXIT HUP INT TERM
  exit "$1"
}
trap 'interrupted_installation 129' HUP
trap 'interrupted_installation 130' INT
trap 'interrupted_installation 143' TERM
trap 'installation_lock release' EXIT
if [[ -e "$current" && ! -L "$current" ]]; then
  printf 'Current release path is occupied: %s\n' "$current" >&2; exit 1
fi
launcher_fingerprint() {
  local path="$1"
  if [[ $runtime_only -eq 1 ]]; then printf 'preserved\n'; return; fi
  if [[ -e "$path" || -L "$path" ]]; then
    if [[ ! -f "$path" || -L "$path" || ! -O "$path" ]] || ! /usr/bin/grep -q '^# Agent companion binary launcher$' "$path"; then
      printf 'Preserving existing command: %s. Move it before installing.\n' "$path" >&2; exit 1
    fi
    /usr/bin/shasum -a 256 "$path"
  else
    printf 'absent\n'
  fi
}
agents_before="$(launcher_fingerprint "$bin_root/agents")"
workspace_before="$(launcher_fingerprint "$bin_root/terminal-workspace")"
stage="$(mktemp -d "$data_root/.agent-companion-download.XXXXXX")"
activated=0
complete=0
previous="$(readlink "$current" || true)"
cleanup() {
  result=$?
  if [[ $activated -eq 1 && $complete -eq 0 ]]; then
    if [[ -n "$previous" ]]; then
      ln -s "$previous" "$stage/restore"
      /bin/mv -fh "$stage/restore" "$current"
    else rm -f -- "$current"; fi
    if [[ $runtime_only -eq 0 ]]; then for command in agents terminal-workspace; do
      if [[ -f "$stage/old-$command" ]]; then
        /bin/mv -f "$stage/old-$command" "$bin_root/$command"
      else rm -f -- "$bin_root/$command"; fi
    done; fi
  fi
  rm -rf -- "$stage"
  installation_lock release
  return "$result"
}
trap cleanup EXIT
# Installers up to 0.3.37 download agent-companion-macos-arm64.tar.gz and
# require its eight-file layout; releases keep that archive for them
# (scripts/package-archives). This installer uses the runtime archive.
archive=agent-companion-runtime-macos-arm64.tar.gz
if [[ -n "$directory" ]]; then
  [[ "$directory" == /* ]] || { printf 'Release directory must be absolute.\n' >&2; exit 2; }
  cp "$directory/$archive" "$directory/SHA256SUMS" "$stage/"
else
  url=https://github.com/Carmezim/agent-companion-releases/releases/latest/download
  for asset in "$archive" SHA256SUMS; do
    /usr/bin/curl --fail --location --proto '=https' --tlsv1.2 --connect-timeout 15 --max-time 180 --max-filesize 67108864 \
      "$url/$asset" --output "$stage/$asset"
  done
fi
expected="$(/usr/bin/awk -v name="$archive" '$2 == name { print $1 }' "$stage/SHA256SUMS")"
[[ ${#expected} -eq 64 && "$expected" != *[^0-9a-f]* ]] || { printf 'Invalid release checksum.\n' >&2; exit 1; }
actual="$(/usr/bin/shasum -a 256 "$stage/$archive")"
[[ "${actual%% *}" == "$expected" ]] || { printf 'Release checksum mismatch.\n' >&2; exit 1; }
cat > "$stage/expected-files" <<'FILES'
bin/agent-companion
bin/agent-companion-tui
install-receipt.json
scripts/agents
scripts/terminal-workspace
FILES
[[ "$(/usr/bin/stat -f %z "$stage/$archive")" -le 67108864 ]] || { printf 'Release archive is too large.\n' >&2; exit 1; }
# Bound decompression before tar interprets headers or writes any runtime file.
/usr/bin/gzip -dc "$stage/$archive" | /usr/bin/perl -e '
  my $total = 0;
  while (1) {
    my $count = sysread(STDIN, my $chunk, 65536);
    die "Archive read failed\n" unless defined $count;
    last if $count == 0;
    $total += $count;
    die "Expanded archive is too large\n" if $total > 111149056;
    print STDOUT $chunk or die "Archive write failed\n";
  }
' > "$stage/archive.tar"
/usr/bin/tar -tf "$stage/archive.tar" | /usr/bin/awk '
  NR > 5 || length($0) > 128 { exit 1 }
  { print }
  END { if (NR != 5) exit 1 }
' | LC_ALL=C /usr/bin/sort > "$stage/actual-files"
/usr/bin/cmp -s "$stage/expected-files" "$stage/actual-files" || { printf 'Unexpected release archive contents.\n' >&2; exit 1; }
# BSD tar with numeric owners has fixed numeric UID, GID and size columns.
LC_ALL=C /usr/bin/tar -tvf "$stage/archive.tar" --numeric-owner | /usr/bin/awk '
  substr($0,1,1) != "-" || $5 !~ /^[0-9]+$/ || $5 > 33554432 { exit 1 }
  { total += $5; count++ }
  END { if (total > 104857600 || count != 5) exit 1 }
' || { printf 'Archive contains links, special files or oversized contents.\n' >&2; exit 1; }
mkdir "$stage/runtime"
/usr/bin/tar -xf "$stage/archive.tar" -C "$stage/runtime"
"$stage/runtime/bin/agent-companion" verify-install --prefix "$stage/runtime"
release="$releases/$expected"
if [[ -e "$release" || -L "$release" ]]; then
  "$stage/runtime/bin/agent-companion" verify-install --prefix "$release"
  /usr/bin/cmp -s "$stage/runtime/install-receipt.json" "$release/install-receipt.json" || { printf 'Existing version differs from the download.\n' >&2; exit 1; }
else /bin/mv "$stage/runtime" "$release"; fi
[[ "$(launcher_fingerprint "$bin_root/agents")" == "$agents_before" && \
   "$(launcher_fingerprint "$bin_root/terminal-workspace")" == "$workspace_before" && \
   "$(readlink "$current" || true)" == "$previous" && ( ! -e "$current" || -L "$current" ) ]] || { printf 'Installation state changed; activation cancelled.\n' >&2; exit 1; }
if [[ $runtime_only -eq 0 ]]; then for command in agents terminal-workspace; do
  [[ ! -f "$bin_root/$command" ]] || cp -p "$bin_root/$command" "$stage/old-$command"
  cat > "$stage/$command" <<'LAUNCHER'
#!/bin/bash
# Agent companion binary launcher
set -euo pipefail
data_root="${XDG_DATA_HOME:-${HOME:+$HOME/.local/share}}"
root="${AGENT_COMPANION_HOME:-${data_root:?Set HOME or XDG_DATA_HOME}/agent-companion-current}"
# Observers from older managed sessions follow the current installed release.
if [[ "COMMAND_NAME" == terminal-workspace ]]; then
  case "${1:-}" in
    event|claude-statusline)
      if [[ -n "$data_root" ]]; then
        case "$root" in
          "$data_root/agent-companion-releases/"*) root="$data_root/agent-companion-current" ;;
        esac
      fi
      ;;
  esac
fi
export AGENT_COMPANION_HOME="$root"
exec "$root/scripts/COMMAND_NAME" "$@"
LAUNCHER
  /usr/bin/sed -i '' "s/COMMAND_NAME/$command/" "$stage/$command"
  chmod 700 "$stage/$command"
done; fi
[[ "$(launcher_fingerprint "$bin_root/agents")" == "$agents_before" && \
   "$(launcher_fingerprint "$bin_root/terminal-workspace")" == "$workspace_before" && \
   "$(readlink "$current" || true)" == "$previous" ]] || { printf 'Installation state changed; activation cancelled.\n' >&2; exit 1; }
ln -s "$release" "$stage/current"
/bin/mv -fh "$stage/current" "$current"
activated=1
if [[ $runtime_only -eq 0 ]]; then
  for command in agents terminal-workspace; do /bin/mv -f "$stage/$command" "$bin_root/$command"; done
fi
if [[ $runtime_only -eq 1 ]]; then
  AGENT_COMPANION_HOME="$release" "$release/scripts/terminal-workspace" --version
else
  "$bin_root/terminal-workspace" --version
fi
complete=1
if ! "$release/bin/agent-companion" setup-pi --refresh; then
  printf 'The app is installed, but the optional Pi adapter could not be refreshed. Run terminal-workspace setup-pi to inspect it.\n' >&2
fi
if [[ $runtime_only -eq 1 ]]; then
  printf '\nUpdated. Reopen your panel to use this version. Your agents keep running.\nEnable direct Claude tracking: terminal-workspace setup-hooks --apply; then restart and resume Claude.\n'
else
  printf '\nInstalled. Add ~/.local/bin to PATH if needed.\nOpen: agents --panel\nWorkspace: brew install tmux; agents --workspace\nEnable native tracking: terminal-workspace setup-hooks --apply; then start or resume your agents.\nPi tracking: terminal-workspace setup-pi --apply; then /reload inside Pi.\n'
fi
