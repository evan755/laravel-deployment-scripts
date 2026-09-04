#!/usr/bin/env bash

set -euo pipefail

dir=$(dirname "$(dirname "$(readlink -f "$0")")")
command="$dir/scripts/Deployment.sh"
config_file="$HOME/.laravel/deployment.json"

# 测试计数
tests_run=0
tests_passed=0
tests_failed=0

# 颜色
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
RESET=$(tput sgr0)

# 断言函数
assert_success() {
  local test_name="$1"
  shift
  ((tests_run++))
  if "$@" >/dev/null 2>&1; then
    ((tests_passed++))
    echo "${GREEN}✓${RESET} $test_name"
  else
    ((tests_failed++))
    echo "${RED}✗${RESET} $test_name"
  fi
}

assert_failure() {
  local test_name="$1"
  shift
  ((tests_run++))
  if "$@" >/dev/null 2>&1; then
    ((tests_failed++))
    echo "${RED}✗${RESET} $test_name (expected failure but succeeded)"
  else
    ((tests_passed++))
    echo "${GREEN}✓${RESET} $test_name"
  fi
}

assert_output_contains() {
  local test_name="$1" expected="$2"
  shift 2
  ((tests_run++))
  local output
  output=$("$@" 2>&1) || true
  if [[ "$output" == *"$expected"* ]]; then
    ((tests_passed++))
    echo "${GREEN}✓${RESET} $test_name"
  else
    ((tests_failed++))
    echo "${RED}✗${RESET} $test_name (output does not contain '$expected')"
    echo "  Actual output: $output"
  fi
}

assert_file_exists() {
  local test_name="$1" file="$2"
  ((tests_run++))
  if [[ -f "$file" ]]; then
    ((tests_passed++))
    echo "${GREEN}✓${RESET} $test_name"
  else
    ((tests_failed++))
    echo "${RED}✗${RESET} $test_name (file not found: $file)"
  fi
}

assert_file_contains() {
  local test_name="$1" file="$2" expected="$3"
  ((tests_run++))
  if [[ -f "$file" ]] && grep -q "$expected" "$file"; then
    ((tests_passed++))
    echo "${GREEN}✓${RESET} $test_name"
  else
    ((tests_failed++))
    echo "${RED}✗${RESET} $test_name (file does not contain '$expected')"
  fi
}

assert_json_value() {
  local test_name="$1" file="$2" key="$3" expected="$4"
  ((tests_run++))
  if [[ -f "$file" ]]; then
    local actual
    actual=$(jq -r ".$key" "$file" 2>/dev/null)
    if [[ "$actual" == "$expected" ]]; then
      ((tests_passed++))
      echo "${GREEN}✓${RESET} $test_name"
    else
      ((tests_failed++))
      echo "${RED}✗${RESET} $test_name (expected '$expected', got '$actual')"
    fi
  else
    ((tests_failed++))
    echo "${RED}✗${RESET} $test_name (file not found: $file)"
  fi
}

# 清理函数
cleanup() {
  rm -rf "$config_file" 2>/dev/null || true
  rm -rf "$HOME/test-apps" 2>/dev/null || true
}

# 测试用例
test_usage() {
  echo ""
  echo "${YELLOW}=== 测试用法说明 ===${RESET}"
  assert_output_contains "无参数显示用法" "Usage:" bash "$command"
  assert_output_contains "无参数显示命令列表" "Commands:" bash "$command"
}

test_config() {
  echo ""
  echo "${YELLOW}=== 测试配置命令 ===${RESET}"
  cleanup

  assert_success "配置命令成功执行" bash "$command" config "$HOME/test-apps" "$(whoami)" 5
  assert_file_exists "配置文件已创建" "$config_file"
  assert_json_value "base_dir 正确" "$config_file" "base_dir" "$HOME/test-apps"
  assert_json_value "runtime_user 正确" "$config_file" "runtime_user" "$(whoami)"
  assert_json_value "keep_versions 正确" "$config_file" "keep_versions" "5"

  assert_failure "配置参数不足失败" bash "$command" config "$HOME/test-apps"
  assert_failure "配置参数过多失败" bash "$command" config "$HOME/test-apps" "$(whoami)" 5 extra
}

test_check() {
  echo ""
  echo "${YELLOW}=== 测试依赖检查 ===${RESET}"

  assert_success "依赖检查成功" bash "$command" check
  assert_json_value "依赖验证状态已更新" "$config_file" "dependencies" "true"
}

test_deploy() {
  echo ""
  echo "${YELLOW}=== 测试部署命令 ===${RESET}"

  # 确保无配置文件
  rm -f "$config_file"
  assert_failure "无配置文件时部署失败" bash "$command" deploy test-app evan755/ai-tutor develop

  # 先配置
  bash "$command" config "$HOME/test-apps" "$(whoami)" 5 >/dev/null 2>&1

  assert_failure "部署参数不足失败" bash "$command" deploy test-app
  assert_failure "部署参数过多失败" bash "$command" deploy test-app repo branch extra
}

test_status() {
  echo ""
  echo "${YELLOW}=== 测试状态命令 ===${RESET}"

  assert_failure "状态参数不足失败" bash "$command" status
  assert_failure "状态参数过多失败" bash "$command" status app1 app2
}

test_versions() {
  echo ""
  echo "${YELLOW}=== 测试版本列表命令 ===${RESET}"

  assert_failure "版本列表参数不足失败" bash "$command" versions
  assert_failure "版本列表参数过多失败" bash "$command" versions app1 app2
}

test_rollback() {
  echo ""
  echo "${YELLOW}=== 测试回滚命令 ===${RESET}"

  assert_failure "回滚参数不足失败" bash "$command" rollback
  assert_failure "回滚参数过多失败" bash "$command" rollback app1 app2
}

test_switch() {
  echo ""
  echo "${YELLOW}=== 测试切换命令 ===${RESET}"

  assert_failure "切换参数不足失败" bash "$command" switch
  assert_failure "切换参数过多失败" bash "$command" switch app1
  assert_failure "切换参数过多失败" bash "$command" switch app1 version extra
}

test_invalid_command() {
  echo ""
  echo "${YELLOW}=== 测试无效命令 ===${RESET}"
  assert_output_contains "无效命令显示用法" "Usage:" bash "$command" invalid
}

# 运行所有测试
main() {
  echo "${YELLOW}=== Laravel Deployment Scripts 测试套件 ===${RESET}"

  test_usage
  test_config
  test_check
  test_deploy
  test_status
  test_versions
  test_rollback
  test_switch
  test_invalid_command

  # 清理
  cleanup

  # 显示结果
  echo ""
  echo "${YELLOW}=== 测试结果 ===${RESET}"
  echo "运行: $tests_run"
  echo "${GREEN}通过: $tests_passed${RESET}"
  echo "${RED}失败: $tests_failed${RESET}"

  if [[ $tests_failed -gt 0 ]]; then
    exit 1
  fi
}

main
