#!/usr/bin/env bash

Logging() {
  local type=$(echo "$1" | tr '[:upper:]' '[:lower:]')
  local message=$2
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S %Z')
  local label color fd

  case "$type" in
      info)
        label="[INFO]"
        color=$(tput setaf 2)
        fd=1
        ;;
      debug)
        label="[DEBUG]"
        color=$(tput setaf 5)
        fd=1
        ;;
      warn)
        label="[WARN]"
        color=$(tput setaf 3)
        fd=1
        ;;
      error)
        label="[ERROR]"
        color=$(tput setaf 1)
        fd=2
        ;;
      fatal)
        label="[FATAL]"
        color=$(tput setaf 1)$(tput bold)$(tput setab 3)  # 红色粗体，黄色背景
        fd=2
        ;;
      *)
        label="[UNKNOWN]"
        color=$(tput setaf 7)$(tput setab 1)  # 白字红底
        fd=2
        ;;
  esac

  printf -v label_fixed "%-9s" "$label"
  local colorEnd=$(tput sgr0)
  local output="${color}${label_fixed} [${timestamp}] ${message} ${colorEnd}"
  if [ "$fd" -eq 1 ]; then
    echo "$output"
  else
    echo "$output" >&2
  fi
}