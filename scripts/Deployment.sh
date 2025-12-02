#!/usr/bin/env bash

set -euo pipefail

script_dir=$(dirname $(readlink -f "$0"))

if [[ -f "${script_dir}/Logging.sh" ]]; then
  source "${script_dir}/Logging.sh"
else
  echo "ERROR: Logging.sh not found in ${script_dir}" >&2
  exit 1
fi

if [[ -f "${script_dir}/Dependencies.sh" ]]; then
  source "${script_dir}/Dependencies.sh"
else
  echo "ERROR: Dependencies.sh not found in ${script_dir}" >&2
  exit 1
fi

function App() {
  checks
  Logging info "Starting Laravel Deployment Scripts"
  Logging info "Deployment completed successfully"
  return 0
}

App;