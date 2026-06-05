#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_SH="$ROOT/scripts/install.sh"

platform_assets() {
  local dir="$1"
  mkdir -p "$dir"
  for file in qs-linux-amd64 qs-linux-arm64 qs-windows-amd64.exe; do
    printf '#!/bin/sh\necho fake-qs\n' > "$dir/$file"
    chmod +x "$dir/$file"
  done
}

test_local_asset_install() {
  local tmp="$1/local"
  local assets="$tmp/assets"
  local install_dir="$tmp/bin"

  platform_assets "$assets"
  mkdir -p "$install_dir"

  QS_RELEASE_BASE_URL="$assets" \
    QS_INSTALL_DIR="$install_dir" \
    QS_INSTALL_COMPLETION=false \
    QS_INSTALL_SKILLS=false \
    bash "$INSTALL_SH" >/dev/null

  if [ ! -f "$install_dir/qs" ] && [ ! -f "$install_dir/qs.exe" ]; then
    echo "local asset install did not produce qs binary" >&2
    exit 1
  fi
}

test_remote_asset_install_uploads_script() {
  local tmp="$1/remote"
  local assets="$tmp/assets"
  local fake_bin="$tmp/bin"
  local install_dir="$tmp/install"
  local ssh_calls="$tmp/ssh-calls"

  mkdir -p "$fake_bin" "$install_dir"
  platform_assets "$assets"

  cat > "$fake_bin/ssh" <<EOF
#!/usr/bin/env bash
target="\$1"
shift
cmd="\$*"
printf '%s\n' "\$cmd" >> '$ssh_calls'
unset QS_INSTALL_TARGET QS_RELEASE_BASE_URL
eval "\$cmd"
EOF
  chmod +x "$fake_bin/ssh"

  PATH="$fake_bin:$PATH" \
    QS_INSTALL_TARGET=fake-host \
    QS_RELEASE_BASE_URL="$assets" \
    QS_INSTALL_DIR="$install_dir" \
    QS_INSTALL_COMPLETION=false \
    QS_INSTALL_SKILLS=false \
    bash "$INSTALL_SH"

  test -f "$install_dir/qs"
  if [ "$(wc -l < "$ssh_calls")" -ne 1 ]; then
    echo "remote asset install should use exactly one ssh session" >&2
    cat "$ssh_calls" >&2
    exit 1
  fi
  grep -F 'bash "${remote_dir}/install.sh"' "$ssh_calls" >/dev/null
}

main() {
  bash -n "$INSTALL_SH"

  local tmp
  tmp="$(mktemp -d)"
  trap "rm -rf '$tmp'" EXIT

  test_local_asset_install "$tmp"
  test_remote_asset_install_uploads_script "$tmp"
}

main "$@"
