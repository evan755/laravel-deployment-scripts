#!/bin/bash

set -euo pipefail

CONFIG_DIR="$HOME/.laravel"
CONFIG_FILE="$CONFIG_DIR/deployment.json"
TIMESTAMP_FORMAT='%Y%m%d-%H%M%S'

UI_RED=$(tput setaf 1)
UI_GREEN=$(tput setaf 2)
UI_YELLOW=$(tput setaf 3)
UI_BLUE=$(tput setaf 4)
UI_MAGENTA=$(tput setaf 5)
UI_CYAN=$(tput setaf 6)
UI_WHITE=$(tput setaf 7)
UI_BOLD=$(tput bold)
UI_DIM=$(tput dim)
UI_RESET=$(tput sgr0)
readonly UI_RED UI_GREEN UI_YELLOW UI_BLUE UI_MAGENTA UI_CYAN UI_WHITE UI_BOLD UI_DIM UI_RESET

Logging() {
  local type message timestamp label color fd
  type=$(echo "$1" | tr '[:upper:]' '[:lower:]')
  message=$2
  timestamp=$(date '+%Y-%m-%d %H:%M:%S %Z')

  case "$type" in
    info)  label="[INFO]";    color=$UI_GREEN;                          fd=1 ;;
    debug) label="[DEBUG]";   color=$UI_MAGENTA;                        fd=1 ;;
    warn)  label="[WARN]";    color=$UI_YELLOW;                         fd=1 ;;
    error) label="[ERROR]";   color=$UI_RED;                            fd=2 ;;
    fatal) label="[FATAL]";   color=${UI_RED}${UI_BOLD}$(tput setab 3); fd=2 ;;
    *)     label="[UNKNOWN]"; color=${UI_WHITE}$(tput setab 1);         fd=2 ;;
  esac

  printf -v label "%-9s" "$label"
  if [[ "$fd" -eq 1 ]]; then
    echo "${color}${label} [${timestamp}] ${message} ${UI_RESET}"
  else
    echo "${color}${label} [${timestamp}] ${message} ${UI_RESET}" >&2
  fi
}

UI() {
  local type="$1"
  shift
  case "$type" in
    title)        _UI_Title "$@" ;;
    subtitle)     _UI_SubTitle "$@" ;;
    section)      _UI_Section "$@" ;;
    info)         _UI_Info "$@" ;;
    success)      _UI_Success "$@" ;;
    warning)      _UI_Warning "$@" ;;
    error)        _UI_Error "$@" ;;
    item)         _UI_Item "$@" ;;
    numitem)      _UI_NumItem "$@" ;;
    keyvalue)     _UI_KeyValue "$@" ;;
    separator)    _UI_Separator "$@" ;;
    progress)     _UI_Progress "$@" ;;
    progressdone) _UI_ProgressDone "$@" ;;
    table)        _UI_Table "$@" ;;
    tablerow)     _UI_TableRow "$@" ;;
    tableend)     _UI_TableEnd "$@" ;;
    menu)         _UI_Menu "$@" ;;
    prompt)       _UI_Prompt "$@" ;;
    environment)  _UI_Environment "$@" ;;
    box)          _UI_Box "$@" ;;
    colortext)    _UI_ColorText "$@" ;;
    *)            _UI_Error "未知 UI 类型: $type" ;;
  esac
}

_UI_Title() {
  local text="$1"
  local width=${2:-60}
  local border
  border=$(printf "%${width}s" | tr ' ' '═')
  echo ""
  echo "${UI_BOLD}${UI_CYAN}╔${border}╗${UI_RESET}"
  printf "%s %-$((width-2))s %s\n" "${UI_BOLD}${UI_CYAN}║${UI_RESET}" "" "${UI_BOLD}${UI_CYAN}║${UI_RESET}"
  printf "%s ${UI_BOLD}${UI_WHITE}%-$((width-3))s${UI_RESET} %s\n" "${UI_BOLD}${UI_CYAN}║${UI_RESET}" "$text" "${UI_BOLD}${UI_CYAN}║${UI_RESET}"
  printf "%s %-$((width-2))s %s\n" "${UI_BOLD}${UI_CYAN}║${UI_RESET}" "" "${UI_BOLD}${UI_CYAN}║${UI_RESET}"
  echo "${UI_BOLD}${UI_CYAN}╚${border}╝${UI_RESET}"
  echo ""
}

_UI_SubTitle() {
  local text="$1"
  local width=${2:-50}
  echo ""
  echo "${UI_CYAN}$(printf "%${width}s" | tr ' ' '─')${UI_RESET}"
  echo "${UI_BOLD}${UI_CYAN}  ${text}${UI_RESET}"
  echo "${UI_CYAN}$(printf "%${width}s" | tr ' ' '─')${UI_RESET}"
  echo ""
}

_UI_Section() {
  local text="$1"
  local width=${2:-60}
  local text_len=${#text}
  local padding=$(( (width - text_len - 4) / 2 ))
  local left_pad right_pad
  left_pad=$(printf "%${padding}s" | tr ' ' '─')
  right_pad=$(printf "%$((width - text_len - padding - 4))s" | tr ' ' '─')
  echo ""
  echo "${UI_DIM}${left_pad}┤ ${UI_BOLD}${text}${UI_RESET}${UI_DIM} ├${right_pad}${UI_RESET}"
  echo ""
}

_UI_Info()    { echo "${UI_BLUE}ℹ${UI_RESET} $1"; }
_UI_Success() { echo "${UI_GREEN}✓${UI_RESET} $1"; }
_UI_Warning() { echo "${UI_YELLOW}⚠${UI_RESET} $1" >&2; }
_UI_Error()   { echo "${UI_RED}✗${UI_RESET} $1" >&2; }

_UI_Item() {
  local indent=${2:-0}
  echo "$(printf "%${indent}s" | tr ' ' ' ')${UI_DIM}•${UI_RESET} $1"
}

_UI_NumItem() {
  local num="$1" message="$2" indent=${3:-0}
  echo "$(printf "%${indent}s" | tr ' ' ' ')${UI_BOLD}${num}.${UI_RESET} ${message}"
}

_UI_KeyValue() {
  local key="$1" value="$2" key_width=${3:-20} indent=${4:-2}
  printf "$(printf "%${indent}s" | tr ' ' ' ')${UI_BOLD}%-${key_width}s${UI_RESET} ${UI_DIM}│${UI_RESET} %s\n" "$key" "$value"
}

_UI_Separator() {
  local width=${1:-60}
  echo "${UI_DIM}$(printf "%${width}s" | tr ' ' '─')${UI_RESET}"
}

_UI_Progress() {
  local current="$1" total="$2" message="${3:-}" width=${4:-30}
  local percent=$(( current * 100 / total ))
  local filled=$(( current * width / total ))
  local empty=$(( width - filled ))
  local bar space
  bar=$(printf "%${filled}s" | tr ' ' '█')
  space=$(printf "%${empty}s" | tr ' ' '░')
  if [ -n "$message" ]; then
    printf "\r%s[%s%s]%s %d%% %s" "${UI_BLUE}" "$bar" "$space" "${UI_RESET}" "$percent" "$message"
  else
    printf "\r%s[%s%s]%s %d%%" "${UI_BLUE}" "$bar" "$space" "${UI_RESET}" "$percent"
  fi
}

_UI_ProgressDone() {
  echo ""
  echo "${UI_GREEN}✓${UI_RESET} ${1:-Done}"
}

_UI_Table() {
  local -n _headers=$1
  local width=${2:-60}
  echo "${UI_DIM}┌$(printf "%${width}s" | tr ' ' '─')┐${UI_RESET}"
  printf "%s" "${UI_DIM}│${UI_RESET}"
  for header in "${_headers[@]}"; do
    printf " %s%s%s" "${UI_BOLD}" "$header" "${UI_RESET}"
  done
  echo "${UI_DIM}│${UI_RESET}"
  echo "${UI_DIM}├$(printf "%${width}s" | tr ' ' '─')┤${UI_RESET}"
}

_UI_TableRow() {
  local -n _values=$1
  local width=${2:-60}
  printf "%s" "${UI_DIM}│${UI_RESET}"
  for value in "${_values[@]}"; do
    printf " %s" "$value"
  done
  echo "${UI_DIM}│${UI_RESET}"
}

_UI_TableEnd() {
  echo "${UI_DIM}└$(printf "%${1:-60}s" | tr ' ' '─')┘${UI_RESET}"
}

_UI_Menu() {
  local title="$1"
  local -n _options=$2
  echo ""
  echo "${UI_BOLD}${title}${UI_RESET}"
  _UI_Separator 40
  local i=1
  for option in "${_options[@]}"; do
    echo "  ${UI_BOLD}${i})${UI_RESET} ${option}"
    ((i++))
  done
  echo ""
}

_UI_Prompt() {
  local message="$1" default="${2:-}"
  if [ -n "$default" ]; then
    printf "%s?%s %s %s[%s]%s: " "${UI_CYAN}" "${UI_RESET}" "$message" "${UI_DIM}" "$default" "${UI_RESET}"
  else
    printf "%s?%s %s: " "${UI_CYAN}" "${UI_RESET}" "$message"
  fi
}

_UI_Environment() {
  local -n _env_items=$1
  echo ""
  echo "${UI_BOLD}Environment${UI_RESET}"
  _UI_Separator 40
  for key in "${!_env_items[@]}"; do
    _UI_KeyValue "$key" "${_env_items[$key]}" 15 2
  done
  echo ""
}

_UI_Box() {
  local title="$1"
  local -n _lines=$2
  local width=${3:-50}
  local inner_width=$((width - 4))
  local box_h="─" box_v="│"
  echo "${UI_DIM}┌$(printf "%${width}s" | tr ' ' "${box_h}")┐${UI_RESET}"
  printf "%s%s%s %-${inner_width}s %s%s%s\n" "${UI_DIM}" "${box_v}" "${UI_RESET}" "$title" "${UI_DIM}" "${box_v}" "${UI_RESET}"
  echo "${UI_DIM}├$(printf "%${width}s" | tr ' ' "${box_h}")┤${UI_RESET}"
  for line in "${_lines[@]}"; do
    printf "%s%s%s %-${inner_width}s %s%s%s\n" "${UI_DIM}" "${box_v}" "${UI_RESET}" "$line" "${UI_DIM}" "${box_v}" "${UI_RESET}"
  done
  echo "${UI_DIM}└$(printf "%${width}s" | tr ' ' "${box_h}")┘${UI_RESET}"
}

_UI_ColorText() {
  local color="$1" text="$2" bold="${3:-false}"
  local color_code
  case "$color" in
    red)     color_code=$UI_RED ;;
    green)   color_code=$UI_GREEN ;;
    yellow)  color_code=$UI_YELLOW ;;
    blue)    color_code=$UI_BLUE ;;
    magenta) color_code=$UI_MAGENTA ;;
    cyan)    color_code=$UI_CYAN ;;
    white)   color_code=$UI_WHITE ;;
    *)       color_code=$UI_RESET ;;
  esac
  if [ "$bold" = "true" ]; then
    echo "${UI_BOLD}${color_code}${text}${UI_RESET}"
  else
    echo "${color_code}${text}${UI_RESET}"
  fi
}

die() {
  Logging error "$1"
  exit 1
}

dependencies=(
  'git'
  'ssh-keygen'
  'jq'
  'aws'
  'php'
  'composer'
  'curl'
)

has_command() {
  command -v "$1" &> /dev/null
}

dependencies_verified() {
  [[ -f "$CONFIG_FILE" ]] && [[ "$(jq -r '.dependencies // false' "$CONFIG_FILE")" == "true" ]]
}

AppDependencies() {
  if dependencies_verified; then
    UI info "依赖已验证，跳过检查"
    return 0
  fi

  UI info "检查所有依赖"
  local failed_deps=()

  for cmd in "${dependencies[@]}"; do
    if has_command "$cmd"; then
      UI success "$cmd"
    else
      UI error "$cmd"
      failed_deps+=("$cmd")
    fi
  done

  if [[ ${#failed_deps[@]} -eq 0 ]]; then
    if [[ -f "$CONFIG_FILE" ]]; then
      local tmp
      tmp=$(mktemp)
      jq '.dependencies = true' "$CONFIG_FILE" > "$tmp" && mv "$tmp" "$CONFIG_FILE"
      UI success "依赖检查通过，已更新配置文件"
    fi
    return 0
  fi

  UI error "以下依赖缺失:"
  for dep in "${failed_deps[@]}"; do
    UI item "$dep"
  done
  return 1
}

config_write() {
  local base_dir="$1" runtime_user="$2" keep_versions="$3"

  if [[ ! -d "$CONFIG_DIR" ]]; then
    mkdir -p "$CONFIG_DIR"
  fi

  local deps_verified="false"
  if [[ -f "$CONFIG_FILE" ]]; then
    deps_verified=$(jq -r '.dependencies // false' "$CONFIG_FILE")
  fi

  jq -n \
    --arg base_dir "$base_dir" \
    --arg runtime_user "$runtime_user" \
    --argjson keep_versions "$keep_versions" \
    --argjson dependencies "$deps_verified" \
    '{base_dir: $base_dir, runtime_user: $runtime_user, keep_versions: $keep_versions, dependencies: $dependencies}' \
    > "$CONFIG_FILE"

  UI success "配置已写入: $CONFIG_FILE"
  UI keyvalue "base_dir" "$base_dir"
  UI keyvalue "runtime_user" "$runtime_user"
  UI keyvalue "keep_versions" "$keep_versions"
}

config_load() {
  if [[ ! -f "$CONFIG_FILE" ]]; then
    die "配置文件不存在: $CONFIG_FILE，请先运行: Deployment.sh config"
  fi
  base_dir=$(jq -r '.base_dir' "$CONFIG_FILE")
  runtime_user=$(jq -r '.runtime_user' "$CONFIG_FILE")
  keep_versions=$(jq -r '.keep_versions' "$CONFIG_FILE")
}

require_args() {
  local expected=$1 actual=$2 usage=$3
  if [[ "$actual" -ne "$expected" ]]; then
    die "$usage"
  fi
}

require_project() {
  local project_name="$1"
  if [[ ! -d "${base_dir}/${project_name}" ]]; then
    die "项目不存在: ${project_name}"
  fi
}

get_version_info() {
  local project_dir="$1"
  current_version=""
  previous_version=""
  if [[ -L "${project_dir}/current" ]]; then
    current_version=$(basename "$(readlink "${project_dir}/current")")
  fi
  if [[ -L "${project_dir}/previous" ]]; then
    previous_version=$(basename "$(readlink "${project_dir}/previous")")
  fi
}

format_timestamp() {
  local ts="$1"
  echo "${ts:0:4}-${ts:4:2}-${ts:6:2} ${ts:9:2}:${ts:11:2}:${ts:13:2}"
}

set_ownership() {
  chown -R "${runtime_user}" "$1"
}

AppConfigure() {
  require_args 3 $# "config 命令需要 3 个参数: <基础目录> <执行用户> <保留版本数量>"
  local base_dir="$1" runtime_user="$2" keep_versions="$3"

  if [[ ! "$keep_versions" =~ ^[1-9][0-9]*$ ]]; then
    die "保留版本数量必须是正整数: $keep_versions"
  fi

  config_write "$base_dir" "$runtime_user" "$keep_versions"
  AppDependencies
}

AppStatus() {
  require_args 1 $# "status 命令需要 1 个参数: <项目名称>"
  config_load
  local project_name="$1"
  local project_dir="${base_dir}/${project_name}"

  require_project "$project_name"
  get_version_info "$project_dir"

  UI subtitle "项目状态: ${project_name}"
  if [[ -n "$current_version" ]]; then
    UI keyvalue "当前版本" "$current_version"
    UI keyvalue "部署时间" "$(format_timestamp "$current_version")"
  else
    UI warning "当前版本: 未部署"
  fi
  UI keyvalue "上一版本" "${previous_version:-无}"

  local version_count
  version_count=$(find "${project_dir}/releases" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
  UI keyvalue "保留版本" "${version_count}/${keep_versions}"
}

AppRollback() {
  require_args 1 $# "rollback 命令需要 1 个参数: <项目名称>"
  config_load
  local project_name="$1"
  local project_dir="${base_dir}/${project_name}"
  local current_link="${project_dir}/current"
  local previous_link="${project_dir}/previous"
  local releases_dir="${project_dir}/releases"

  require_project "$project_name"
  if [[ ! -L "$previous_link" ]]; then
    die "没有可回滚的版本"
  fi

  local previous_target previous_version
  previous_target=$(readlink "$previous_link")
  previous_version=$(basename "$previous_target")

  UI subtitle "开始回滚: ${project_name}"
  UI keyvalue "回滚到" "$previous_version"

  ln -sfn "$previous_target" "$current_link"

  local versions=()
  while IFS= read -r dir; do
    versions+=("$dir")
  done < <(find "${releases_dir}" -maxdepth 1 -mindepth 1 -type d | sort -r)
  local new_previous=""

  for i in "${!versions[@]}"; do
    if [[ "$(basename "${versions[$i]}")" == "$previous_version" && $((i + 1)) -lt ${#versions[@]} ]]; then
      new_previous="releases/$(basename "${versions[$((i + 1))]}")"
      break
    fi
  done

  if [[ -n "$new_previous" ]]; then
    ln -sfn "$new_previous" "$previous_link"
  else
    rm -f "$previous_link"
  fi

  set_ownership "${project_dir}/${previous_target}"
  UI success "回滚完成: ${project_name} -> ${previous_version}"
}

AppVersions() {
  require_args 1 $# "versions 命令需要 1 个参数: <项目名称>"
  config_load
  local project_name="$1"
  local project_dir="${base_dir}/${project_name}"

  require_project "$project_name"
  get_version_info "$project_dir"

  UI subtitle "版本列表: ${project_name}"

  local versions=()
  while IFS= read -r dir; do
    versions+=("$dir")
  done < <(find "${project_dir}/releases" -maxdepth 1 -mindepth 1 -type d | sort -r)
  if [[ ${#versions[@]} -eq 0 ]]; then
    UI warning "（无版本）"
    return 0
  fi

  for dir in "${versions[@]}"; do
    local version time marker=""
    version=$(basename "$dir")
    time=$(format_timestamp "$version")

    if [[ "$version" == "$current_version" ]]; then
      marker=" <- current"
    elif [[ "$version" == "$previous_version" ]]; then
      marker=" <- previous"
    fi
    UI item "${version}  ${time}${marker}"
  done
}

AppSwitch() {
  require_args 2 $# "switch 命令需要 2 个参数: <项目名称> <版本>"
  config_load
  local project_name="$1" target_version="$2"
  local project_dir="${base_dir}/${project_name}"
  local current_link="${project_dir}/current"
  local previous_link="${project_dir}/previous"
  local target_dir="${project_dir}/releases/${target_version}"

  require_project "$project_name"
  if [[ ! -d "$target_dir" ]]; then
    die "版本不存在: ${target_version}"
  fi

  UI subtitle "切换版本: ${project_name}"
  UI keyvalue "目标版本" "$target_version"

  if [[ -L "$current_link" ]]; then
    local old_current
    old_current=$(readlink "$current_link")
    ln -sfn "$old_current" "$previous_link"
  fi

  ln -sfn "releases/${target_version}" "$current_link"

  set_ownership "$target_dir"
  UI success "切换完成: ${project_name} -> ${target_version}"
}

AppDeployment() {
  require_args 3 $# "deploy 命令需要 3 个参数: <项目名称> <组织/仓库> <部署分支>"
  config_load
  local project_name="$1" repo="$2" branch="$3"
  local timestamp
  timestamp=$(date "+$TIMESTAMP_FORMAT")
  local project_dir="${base_dir}/${project_name}"
  local releases_dir="${project_dir}/releases"
  local release_dir="${releases_dir}/${timestamp}"
  local current_link="${project_dir}/current"
  local previous_link="${project_dir}/previous"
  local shared_dir="${project_dir}/shared"

  UI subtitle "开始部署: ${project_name}"
  UI keyvalue "仓库" "$repo"
  UI keyvalue "分支" "$branch"
  UI keyvalue "版本" "$timestamp"

  if [[ ! -d "$releases_dir" ]]; then
    mkdir -p "$releases_dir" \
      "$shared_dir/storage/app" \
      "$shared_dir/storage/framework" \
      "$shared_dir/storage/logs" \
      "$shared_dir/uploads" \
      "$shared_dir/public/uploads"
  fi

  UI info "克隆代码: git@github.com:${repo}.git -> ${release_dir}"
  git clone -b "$branch" "git@github.com:${repo}.git" "$release_dir"

  rm -rf "${release_dir}/storage" "${release_dir}/public/uploads" 2>/dev/null || true
  mkdir -p "${release_dir}/public"
  ln -sfn "../../shared/storage" "${release_dir}/storage"
  ln -sfn "../../shared/uploads" "${release_dir}/public/uploads"

  set_ownership "$release_dir"

  if [[ -L "$current_link" ]]; then
    local old_current
    old_current=$(readlink "$current_link")
    ln -sfn "$old_current" "$previous_link"
  fi

  ln -sfn "releases/${timestamp}" "$current_link"

  local version_count
  version_count=$(find "${releases_dir}" -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' ')
  if [[ "$version_count" -gt "$keep_versions" ]]; then
    local current_target previous_target
    current_target=$(basename "$(readlink -f "$current_link")" 2>/dev/null || echo "")
    previous_target=$(basename "$(readlink -f "$previous_link")" 2>/dev/null || echo "")

    find "${releases_dir}" -maxdepth 1 -mindepth 1 -type d | sort -r | tail -n +$((keep_versions + 1)) | while read -r dir; do
      local dir_name
      dir_name=$(basename "$dir")
      if [[ "$dir_name" != "$current_target" && "$dir_name" != "$previous_target" ]]; then
        rm -rf "$dir"
      fi
    done
  fi

  UI success "部署完成: ${project_name} (${timestamp})"
}

AppUsage() {
  cat <<EOF >&2

Laravel Deployment Scripts

Usage: Deployment.sh <command> [args...]

Commands:
  deploy   <name> <repo> <branch>   Deploy project
  status   <name>                   Show deploy status
  rollback <name>                   Rollback to previous version
  versions <name>                   List all versions
  switch   <name> <version>         Switch to specific version
  config   <dir> <user> <versions>  Configure settings
  check                             Check dependencies

EOF
  exit 1
}

App() {
  local command="${1:-}"
  shift || true

  case "$command" in
    check)    AppDependencies "$@" ;;
    config)   AppConfigure "$@" ;;
    deploy)   AppDeployment "$@" ;;
    status)   AppStatus "$@" ;;
    rollback) AppRollback "$@" ;;
    versions) AppVersions "$@" ;;
    switch)   AppSwitch "$@" ;;
    *)        AppUsage ;;
  esac
}

App "$@"
