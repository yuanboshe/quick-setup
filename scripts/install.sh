#!/bin/bash

set -e

DEFAULT_VERSION="v0.4.0"
VERSION="${QS_VERSION:-${DEFAULT_VERSION}}"
BASE_URL="https://github.com/yuanboshe/quick-setup/releases/download/${VERSION}/"
PROXY="${1:-${QS_DOWNLOAD_PREFIX:-}}"
CURL_CONNECT_TIMEOUT="${QS_CURL_CONNECT_TIMEOUT:-8}"
CURL_MAX_TIME="${QS_CURL_MAX_TIME:-120}"
CURL_RETRY="${QS_CURL_RETRY:-2}"
# 发布方可以在这里填入默认镜像或 GHX 转发入口，多个值用空格或逗号分隔。
DEFAULT_RELEASE_BASE_URLS=""
DEFAULT_GHX_BASE_URLS="https://ghx-cache.pz1.top https://ghx.pz1.top"
INSTALL_COMPLETION="${QS_INSTALL_COMPLETION:-true}"
INSTALL_SKILLS="${QS_INSTALL_SKILLS:-true}"
SKILL_BASE_URL="${QS_SKILL_BASE_URL:-https://qs.pz1.top/skills}"
AGENTS_HOME="${AGENTS_HOME:-${HOME}/.agents}"
SKILLS_DIR="${QS_SKILLS_DIR:-${AGENTS_HOME}/skills}"
AGENT_SKILL_LINKS="${QS_AGENT_SKILL_LINKS:-auto}"
INSTALL_TARGET="${QS_INSTALL_TARGET:-}"
INSTALL_SCRIPT_URL="${QS_INSTALL_SCRIPT_URL:-https://qs.pz1.top/install.sh}"

if [[ ! "${VERSION}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z][0-9A-Za-z.-]*)?$ ]]; then
    echo "Invalid QS_VERSION: ${VERSION}. Expected v0.3.0 or v0.4.0-rc.1." >&2
    exit 1
fi

urlencode() {
    local raw="$1"
    local encoded=""
    local i char hex
    for ((i = 0; i < ${#raw}; i++)); do
        char="${raw:i:1}"
        case "${char}" in
            [a-zA-Z0-9.~_-])
                encoded+="${char}"
                ;;
            *)
                printf -v hex '%%%02X' "'${char}"
                encoded+="${hex}"
                ;;
        esac
    done
    printf '%s' "${encoded}"
}

ghx_proxy_url() {
    local base="${1%/}"
    local target="$2"
    local sep="?"
    if [[ "${base}" == *"?"* ]]; then
        sep="&"
    fi
    printf '%s%surl=%s' "${base}" "${sep}" "$(urlencode "${target}")"
}

is_http_url() {
    local value="$1"
    [[ "${value}" == http://* || "${value}" == https://* ]]
}

shell_quote() {
    printf '%q' "$1"
}

current_script_path() {
    local source="${BASH_SOURCE[0]:-${0}}"
    local base

    if [ -z "${source}" ]; then
        return 1
    fi
    base="$(basename "${source}")"
    case "${base}" in
        bash|bash.exe|sh|sh.exe)
            return 1
            ;;
    esac
    if [ ! -f "${source}" ]; then
        return 1
    fi
    (
        cd "$(dirname "${source}")"
        printf '%s/%s' "$(pwd -P)" "$(basename "${source}")"
    )
}

download_one() {
    local url="$1"
    local output="$2"
    local mode="${3:-direct}"
    local extra_args=()
    if [ "${mode}" = "ghx" ] && [ -n "${QS_GHX_TOKEN:-}" ]; then
        extra_args=(-H "X-GHX-Token: ${QS_GHX_TOKEN}")
    fi
    curl -fsSL \
        --connect-timeout "${CURL_CONNECT_TIMEOUT}" \
        --max-time "${CURL_MAX_TIME}" \
        --retry "${CURL_RETRY}" \
        --retry-delay 1 \
        "${extra_args[@]}" \
        -o "${output}" \
        "${url}"
}

append_url_list() {
    local list="$1"
    local -n output_ref="$2"
    local item
    list="${list//,/ }"
    for item in ${list}; do
        if [ -n "${item}" ]; then
            output_ref+=("${item}")
        fi
    done
}

copy_local_asset() {
    local base="$1"
    local asset="$2"
    local output="$3"
    local source="${base%/}/${asset}"

    if [ -f "${source}" ]; then
        echo "Use local ${asset} from ${source} ..."
        cp "${source}" "${output}"
        return 0
    fi
    if [ "${asset}" = "SHA256SUMS" ] && [ -n "${FILE:-}" ] && [ -f "${base%/}/${FILE}" ]; then
        echo "Generate SHA256SUMS from ${base%/}/${FILE} ..."
        (cd "${base}" && sha256sum "${FILE}") > "${output}"
        return 0
    fi
    echo "Local asset not found: ${source}" >&2
    return 1
}

normalize_platform() {
    local raw_os="$1"
    local raw_arch="$2"

    case "${raw_arch}" in
        x86_64|amd64)
            ARCH="amd64"
            ;;
        aarch64|arm64)
            ARCH="arm64"
            ;;
        *)
            echo "Unsupported architecture: ${raw_arch}" >&2
            exit 1
            ;;
    esac

    case "${raw_os}" in
        Linux)
            OS="linux"
            ;;
        MINGW*|MSYS*|CYGWIN*)
            OS="windows"
            ;;
        *)
            echo "Unsupported operating system: ${raw_os}" >&2
            exit 1
            ;;
    esac

    FILE="qs-${OS}-${ARCH}"
    INSTALL_NAME="qs"
    if [ "${OS}" = "windows" ]; then
        FILE="${FILE}.exe"
        INSTALL_NAME="qs.exe"
    fi
}

detect_local_platform() {
    normalize_platform "$(uname -s)" "$(uname -m)"
}

remote_env_prefix() {
    local include_release_base="$1"
    local names=(
        QS_VERSION
        QS_HOME
        QS_INSTALL_DIR
        QS_INSTALL_COMPLETION
        QS_INSTALL_SKILLS
        QS_SKILL_BASE_URL
        QS_SKILLS_DIR
        QS_AGENT_SKILL_LINKS
        QS_GHX_BASE_URL
        QS_GHX_BASE_URLS
        QS_GHX_TOKEN
        QS_CURL_CONNECT_TIMEOUT
        QS_CURL_MAX_TIME
        QS_CURL_RETRY
        AGENTS_HOME
    )
    local name value output=""

    if [ "${include_release_base}" = "true" ]; then
        names+=(QS_RELEASE_BASE_URL QS_RELEASE_BASE_URLS)
    fi
    for name in "${names[@]}"; do
        value="${!name:-}"
        if [ -n "${value}" ]; then
            output+="${name}=$(shell_quote "${value}") "
        fi
    done
    printf '%s' "${output}"
}

run_remote_install_from_url() {
    local target="$1"
    local env_prefix

    env_prefix="$(remote_env_prefix true)"
    ssh "${target}" "curl -fsSL $(shell_quote "${INSTALL_SCRIPT_URL}") | ${env_prefix}bash"
}

run_remote_install_from_local_assets() {
    local target="$1"
    local asset_dir="$2"
    local script_path=""
    local stage_dir
    local env_prefix
    local remote_cmd
    local asset_path
    local has_asset=0

    if [ ! -d "${asset_dir}" ]; then
        echo "Local release asset directory not found: ${asset_dir}" >&2
        exit 1
    fi

    stage_dir="$(mktemp -d)"
    for asset_path in "${asset_dir%/}"/qs-*; do
        if [ -f "${asset_path}" ]; then
            cp "${asset_path}" "${stage_dir}/$(basename "${asset_path}")"
            has_asset=1
        fi
    done
    if [ "${has_asset}" -ne 1 ]; then
        echo "Local release asset directory should contain qs-* files: ${asset_dir}" >&2
        rm -rf "${stage_dir}"
        exit 1
    fi
    if script_path="$(current_script_path)"; then
        cp "${script_path}" "${stage_dir}/install.sh"
    fi
    if [ -f "${asset_dir%/}/SHA256SUMS" ]; then
        cp "${asset_dir%/}/SHA256SUMS" "${stage_dir}/SHA256SUMS"
    fi

    env_prefix="$(remote_env_prefix false)"
    remote_cmd="set -e; remote_dir=\$(mktemp -d \"\${TMPDIR:-/tmp}/qs-install-assets.XXXXXX\"); trap 'rm -rf \"\${remote_dir}\"' EXIT; tar -C \"\${remote_dir}\" -xf -; if [ -f \"\${remote_dir}/install.sh\" ]; then ${env_prefix}QS_RELEASE_ASSET_DIR=\"\${remote_dir}\" bash \"\${remote_dir}/install.sh\"; else curl -fsSL $(shell_quote "${INSTALL_SCRIPT_URL}") | ${env_prefix}QS_RELEASE_ASSET_DIR=\"\${remote_dir}\" bash; fi"
    tar -C "${stage_dir}" -cf - . | ssh "${target}" "${remote_cmd}"
    rm -rf "${stage_dir}"
}

run_remote_install() {
    local target="${INSTALL_TARGET}"

    if [ -z "${target}" ]; then
        return 0
    fi
    if [ -n "${QS_RELEASE_BASE_URL:-}" ] && ! is_http_url "${QS_RELEASE_BASE_URL}" && [ -d "${QS_RELEASE_BASE_URL}" ]; then
        run_remote_install_from_local_assets "${target}" "${QS_RELEASE_BASE_URL}"
    else
        run_remote_install_from_url "${target}"
    fi
    exit 0
}

ensure_bashrc_sources_completion() {
    local completion_file="$1"
    local bashrc="${HOME}/.bashrc"

    if ! touch "${bashrc}" 2>/dev/null; then
        echo "Skip updating ${bashrc}: no write permission."
        return 0
    fi
    if ! grep -F "${completion_file}" "${bashrc}" >/dev/null 2>&1; then
        {
            echo
            echo "# quick-setup completion"
            echo 'case $- in'
            printf '    *i*) [ -f "%s" ] && . "%s" ;;\n' "${completion_file}" "${completion_file}"
            echo 'esac'
        } >> "${bashrc}"
    fi
}

print_completion_next_steps() {
    local completion_file="$1"

    echo "Open a new bash shell to use qs completion."
    echo "To enable it in the current shell now, run: source ${completion_file}"
}

download_asset() {
    local asset="$1"
    local output="$2"
    local upstream="${BASE_URL}${asset}"
    local url
    local base
    local release_base_urls=()
    local ghx_base_urls=()

    if [ -n "${QS_RELEASE_ASSET_DIR:-}" ]; then
        copy_local_asset "${QS_RELEASE_ASSET_DIR}" "${asset}" "${output}"
        return $?
    fi

    if [ -n "${QS_RELEASE_BASE_URL:-}" ]; then
        release_base_urls+=("${QS_RELEASE_BASE_URL}")
    fi
    append_url_list "${QS_RELEASE_BASE_URLS:-}" release_base_urls
    append_url_list "${DEFAULT_RELEASE_BASE_URLS}" release_base_urls

    if [ -n "${QS_GHX_BASE_URL:-}" ]; then
        ghx_base_urls+=("${QS_GHX_BASE_URL}")
    fi
    append_url_list "${QS_GHX_BASE_URLS:-}" ghx_base_urls
    append_url_list "${DEFAULT_GHX_BASE_URLS}" ghx_base_urls

    for base in "${release_base_urls[@]}"; do
        if ! is_http_url "${base}"; then
            copy_local_asset "${base}" "${asset}" "${output}" && return 0
            echo "Local asset failed: ${base%/}/${asset}" >&2
            continue
        fi
        url="${base%/}/${asset}"
        echo "Download ${asset} from ${url} ..."
        if download_one "${url}" "${output}"; then
            return 0
        fi
        echo "Download failed: ${url}" >&2
    done

    for base in "${ghx_base_urls[@]}"; do
        url="$(ghx_proxy_url "${base}" "${upstream}")"
        echo "Download ${asset} through GHX proxy ${base} ..."
        if download_one "${url}" "${output}" "ghx"; then
            return 0
        fi
        echo "Download failed through GHX proxy: ${base}" >&2
    done

    if [ -n "${PROXY}" ]; then
        url="${PROXY}${upstream}"
        echo "Download ${asset} from ${url} ..."
        if download_one "${url}" "${output}"; then
            return 0
        fi
        echo "Download failed: ${url}" >&2
    fi

    echo "Download ${asset} from ${upstream} ..."
    if download_one "${upstream}" "${output}"; then
        return 0
    fi

    echo "Failed to download ${asset}." >&2
    echo "If GitHub is unreachable, set QS_GHX_BASE_URL, QS_GHX_BASE_URLS, QS_RELEASE_BASE_URL or QS_RELEASE_BASE_URLS and retry." >&2
    return 1
}

install_completion() {
    if [ "${INSTALL_COMPLETION}" = "false" ] || [ "${INSTALL_COMPLETION}" = "0" ]; then
        return 0
    fi

    local qs_bin="${INSTALL_DIR}/${INSTALL_NAME}"
    local completion_tmp="${TMP_DIR}/qs.bash"
    local user_completion_dir
    local user_completion_file
    local system_completion_file="/etc/bash_completion.d/qs"

    if ! "${qs_bin}" completion bash > "${completion_tmp}" 2>/dev/null; then
        echo "Skip bash completion: qs completion bash failed."
        return 0
    fi

    if [ "${OS}" = "linux" ]; then
        if [ -d "/etc/bash_completion.d" ]; then
            if [ -w "/etc/bash_completion.d" ]; then
                cp "${completion_tmp}" "${system_completion_file}"
                echo "bash completion has been installed to ${system_completion_file}"
                print_completion_next_steps "${system_completion_file}"
                return 0
            fi
            if command -v sudo >/dev/null 2>&1; then
                sudo cp "${completion_tmp}" "${system_completion_file}"
                echo "bash completion has been installed to ${system_completion_file}"
                print_completion_next_steps "${system_completion_file}"
                return 0
            fi
        fi

        user_completion_dir="${HOME}/.local/share/bash-completion/completions"
        user_completion_file="${user_completion_dir}/qs"
        mkdir -p "${user_completion_dir}"
        cp "${completion_tmp}" "${user_completion_file}"
        ensure_bashrc_sources_completion "${user_completion_file}"
        echo "bash completion has been installed to ${user_completion_file}"
        print_completion_next_steps "${user_completion_file}"
        return 0
    fi

    user_completion_dir="${HOME}/.bash_completion.d"
    user_completion_file="${user_completion_dir}/qs"
    mkdir -p "${user_completion_dir}"
    cp "${completion_tmp}" "${user_completion_file}"
    ensure_bashrc_sources_completion "${user_completion_file}"
    echo "bash completion has been installed to ${user_completion_file}"
    print_completion_next_steps "${user_completion_file}"
}

is_path_reference() {
    local path="$1"
    local path_win

    if [ -L "${path}" ]; then
        return 0
    fi
    if [ "${OS}" = "windows" ] && [ -e "${path}" ] && command -v cmd.exe >/dev/null 2>&1 && command -v cygpath >/dev/null 2>&1; then
        path_win="$(cygpath -aw "${path}")"
        if MSYS2_ARG_CONV_EXCL='*' cmd.exe /c fsutil reparsepoint query "${path_win}" >/dev/null 2>&1; then
            return 0
        fi
    fi
    return 1
}

install_skill() {
    local skill_name="$1"
    local skill_url="${SKILL_BASE_URL%/}/${skill_name}/SKILL.md"
    local skill_dir="${SKILLS_DIR}/${skill_name}"
    local skill_tmp="${TMP_DIR}/${skill_name}.SKILL.md"

    if is_path_reference "${skill_dir}"; then
        echo "Keep Agent skill reference ${skill_dir}; skip managed skill update."
        return 0
    fi
    if [ -e "${skill_dir}" ] && [ ! -d "${skill_dir}" ]; then
        echo "Skip Agent skill ${skill_name}: ${skill_dir} exists and is not a directory."
        return 0
    fi

    echo "Install Agent skill ${skill_name} from ${skill_url} ..."
    if ! download_one "${skill_url}" "${skill_tmp}"; then
        echo "Skip Agent skill ${skill_name}: download failed."
        return 0
    fi

    if ! mkdir -p "${skill_dir}" 2>/dev/null; then
        echo "Skip Agent skill ${skill_name}: cannot create ${skill_dir}."
        return 0
    fi

    if ! cp "${skill_tmp}" "${skill_dir}/SKILL.md" 2>/dev/null; then
        echo "Skip Agent skill ${skill_name}: cannot write ${skill_dir}/SKILL.md."
        return 0
    fi
    echo "Agent skill ${skill_name} has been installed to ${skill_dir}/SKILL.md"
}

append_unique_dir() {
    local dir="$1"
    local existing

    if [ -z "${dir}" ]; then
        return 0
    fi
    for existing in "${DETECTED_AGENT_SKILL_DIRS[@]}"; do
        if [ "${existing}" = "${dir}" ]; then
            return 0
        fi
    done
    DETECTED_AGENT_SKILL_DIRS+=("${dir}")
}

detect_agent_skill_dirs() {
    DETECTED_AGENT_SKILL_DIRS=()

    if [ "${AGENT_SKILL_LINKS}" = "false" ] || [ "${AGENT_SKILL_LINKS}" = "0" ]; then
        return 0
    fi

    if [ "${AGENT_SKILL_LINKS}" != "auto" ]; then
        local links="${AGENT_SKILL_LINKS//,/ }"
        local dir
        for dir in ${links}; do
            append_unique_dir "${dir}"
        done
        return 0
    fi

    if [ -n "${CODEX_HOME:-}" ]; then
        append_unique_dir "${CODEX_HOME}/skills"
    elif [ -d "${HOME}/.codex" ]; then
        append_unique_dir "${HOME}/.codex/skills"
    fi

    if [ -n "${CLAUDE_HOME:-}" ]; then
        append_unique_dir "${CLAUDE_HOME}/skills"
    elif [ -d "${HOME}/.claude" ]; then
        append_unique_dir "${HOME}/.claude/skills"
    fi
}

link_installed_skill() {
    local skill_name="$1"
    local source_dir="${SKILLS_DIR}/${skill_name}"
    local target_base
    local target_dir
    local source_win
    local target_win

    if [ ! -f "${source_dir}/SKILL.md" ]; then
        return 0
    fi

    for target_base in "${DETECTED_AGENT_SKILL_DIRS[@]}"; do
        target_dir="${target_base}/${skill_name}"
        if [ "${target_dir}" = "${source_dir}" ]; then
            continue
        fi
        mkdir -p "${target_base}" 2>/dev/null || {
            echo "Skip Agent skill reference ${target_dir}: cannot create ${target_base}."
            continue
        }
        if is_path_reference "${target_dir}"; then
            echo "Keep existing Agent skill reference ${target_dir}."
            continue
        fi
        if [ -e "${target_dir}" ]; then
            echo "Skip Agent skill reference ${target_dir}: non-reference path already exists."
            continue
        fi
        if [ "${OS}" = "windows" ] && command -v cmd.exe >/dev/null 2>&1 && command -v cygpath >/dev/null 2>&1; then
            source_win="$(cygpath -aw "${source_dir}")"
            target_win="$(cygpath -aw "${target_dir}")"
            if MSYS2_ARG_CONV_EXCL='*' cmd.exe /c mklink /J "${target_win}" "${source_win}" >/dev/null 2>&1; then
                echo "Agent skill ${skill_name} has been linked to ${target_dir}"
            else
                echo "Skip Agent skill reference ${target_dir}: cannot create link."
            fi
        elif ln -s "${source_dir}" "${target_dir}" 2>/dev/null; then
            echo "Agent skill ${skill_name} has been linked to ${target_dir}"
        else
            echo "Skip Agent skill reference ${target_dir}: cannot create link."
        fi
    done
}

install_skills() {
    if [ "${INSTALL_SKILLS}" = "false" ] || [ "${INSTALL_SKILLS}" = "0" ]; then
        return 0
    fi

    detect_agent_skill_dirs
    install_skill "qs-cmd"
    link_installed_skill "qs-cmd"
    install_skill "qs-repo"
    link_installed_skill "qs-repo"
}

init_default_config() {
    local qs_bin="${INSTALL_DIR}/${INSTALL_NAME}"

    if [ ! -x "${qs_bin}" ]; then
        echo "Skip default config init: ${qs_bin} is not executable."
        return 0
    fi
    if "${qs_bin}" config init >/dev/null; then
        echo "QS default config is ready."
        return 0
    fi
    echo "Failed to initialize QS default config. Run '${qs_bin} config init' manually." >&2
    return 1
}

run_remote_install
detect_local_platform
if [ -n "${QS_INSTALL_DIR:-}" ]; then
    INSTALL_DIR="${QS_INSTALL_DIR}"
elif [ "${OS}" = "windows" ]; then
    INSTALL_DIR="${HOME}/bin"
else
    INSTALL_DIR="/usr/local/bin"
fi
TMP_DIR="$(mktemp -d)"

cleanup() {
    rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

download_asset "${FILE}" "${TMP_DIR}/${FILE}"

if command -v sha256sum >/dev/null 2>&1; then
    download_asset "SHA256SUMS" "${TMP_DIR}/SHA256SUMS"
    (cd "${TMP_DIR}" && awk -v file="${FILE}" '$2 == file || $2 == "*" file { print }' SHA256SUMS | sha256sum -c -)
else
    echo "sha256sum not found, skip checksum verification"
fi

chmod +x "${TMP_DIR}/${FILE}"
if [ ! -d "${INSTALL_DIR}" ]; then
    if ! mkdir -p "${INSTALL_DIR}" 2>/dev/null; then
        if command -v sudo >/dev/null 2>&1; then
            sudo mkdir -p "${INSTALL_DIR}"
        else
            echo "Cannot create install directory: ${INSTALL_DIR}"
            exit 1
        fi
    fi
fi

if [ -w "${INSTALL_DIR}" ]; then
    mv "${TMP_DIR}/${FILE}" "${INSTALL_DIR}/${INSTALL_NAME}"
elif command -v sudo >/dev/null 2>&1; then
    sudo mv "${TMP_DIR}/${FILE}" "${INSTALL_DIR}/${INSTALL_NAME}"
else
    echo "No write permission for ${INSTALL_DIR} and sudo is not available"
    exit 1
fi

echo "qs has been installed to ${INSTALL_DIR}/${INSTALL_NAME}"
init_default_config
install_completion
install_skills
case ":${PATH}:" in
    *":${INSTALL_DIR}:"*)
        ;;
    *)
        echo "Add ${INSTALL_DIR} to PATH if qs is not found in a new shell."
        ;;
esac
