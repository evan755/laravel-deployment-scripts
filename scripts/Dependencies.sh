#!/usr/bin/env bash

set -euo pipefail

dependencies=(
  'jq'
  'aws'
  'php'
  'composer'
  'curl'
)

check() {
  if command -v "$1" &> /dev/null; then
    return 0
  else
    return 1
  fi
}

checks() {
  Logging info "# 检查所有依赖"
  local all_success=true

  for dependency in "${dependencies[@]}"; do
    if check "$dependency"; then
      Logging info "## $dependency  ✅ "
    else
      Logging error "## $dependency  ❌ "
      all_success=false
    fi
  done

  if [ "$all_success" = true ]; then
    return 0
  else
    return 1
  fi
}