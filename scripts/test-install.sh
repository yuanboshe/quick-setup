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

skill_assets() {
  local dir="$1"
  mkdir -p "$dir/qs-cmd" "$dir/qs-repo"
  printf '%s\n' 'qs-cmd published' > "$dir/qs-cmd/SKILL.md"
  printf '%s\n' 'qs-repo published' > "$dir/qs-repo/SKILL.md"
}

run_local_install_with_skills() {
  local tmp="$1"
  local agents_home="$2"
  local agent_links="$3"
  local assets="$tmp/assets"
  local skill_source="$tmp/skill-source"
  local install_dir="$tmp/bin"

  platform_assets "$assets"
  skill_assets "$skill_source"
  mkdir -p "$install_dir"

  AGENTS_HOME="$agents_home" \
    QS_AGENT_SKILL_LINKS="$agent_links" \
    QS_RELEASE_BASE_URL="$assets" \
    QS_SKILL_BASE_URL="file://$skill_source" \
    QS_INSTALL_DIR="$install_dir" \
    QS_INSTALL_COMPLETION=false \
    bash "$INSTALL_SH" >/dev/null
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

test_skill_install_updates_managed_directory() {
  local tmp="$1/skill-update"
  local agents_home="$tmp/agents"

  mkdir -p "$agents_home/skills/qs-cmd"
  printf '%s\n' 'qs-cmd old' > "$agents_home/skills/qs-cmd/SKILL.md"

  run_local_install_with_skills "$tmp" "$agents_home" false

  grep -Fx 'qs-cmd published' "$agents_home/skills/qs-cmd/SKILL.md" >/dev/null
  grep -Fx 'qs-repo published' "$agents_home/skills/qs-repo/SKILL.md" >/dev/null
}

test_skill_install_preserves_managed_reference() {
  local tmp="$1/skill-managed-reference"
  local agents_home="$tmp/agents"
  local development_skill="$tmp/development/qs-cmd"

  mkdir -p "$agents_home/skills" "$development_skill"
  printf '%s\n' 'qs-cmd development' > "$development_skill/SKILL.md"
  ln -s "$development_skill" "$agents_home/skills/qs-cmd"

  run_local_install_with_skills "$tmp" "$agents_home" false

  test -L "$agents_home/skills/qs-cmd"
  grep -Fx 'qs-cmd development' "$development_skill/SKILL.md" >/dev/null
}

test_skill_link_preserves_existing_reference() {
  local tmp="$1/skill-agent-reference"
  local agents_home="$tmp/agents"
  local agent_skills="$tmp/agent-skills"
  local development_skill="$tmp/development/qs-cmd"

  mkdir -p "$agent_skills" "$development_skill"
  printf '%s\n' 'qs-cmd development' > "$development_skill/SKILL.md"
  ln -s "$development_skill" "$agent_skills/qs-cmd"

  run_local_install_with_skills "$tmp" "$agents_home" "$agent_skills"

  test -L "$agent_skills/qs-cmd"
  grep -Fx 'qs-cmd development' "$development_skill/SKILL.md" >/dev/null
  test -L "$agent_skills/qs-repo"
}

main() {
  bash -n "$INSTALL_SH"

  local tmp
  tmp="$(mktemp -d)"
  trap "rm -rf '$tmp'" EXIT

  test_local_asset_install "$tmp"
  test_remote_asset_install_uploads_script "$tmp"
  test_skill_install_updates_managed_directory "$tmp"
  test_skill_install_preserves_managed_reference "$tmp"
  test_skill_link_preserves_existing_reference "$tmp"
}

main "$@"
