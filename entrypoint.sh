#!/bin/bash
#
# Scans a pull request's commits (or, on push, the whole history) with
# gitleaks v8, which honours the fingerprints in the repository's
# .gitleaksignore. A config that gitleaks v8 cannot load (one still in the
# gitleaks v7 format) is run with gitleaks v7 instead, with a warning to
# migrate it.

set -uo pipefail

workspace="${GITHUB_WORKSPACE:?}"
input_config="${1:-}"

config=""
if [ -n "$input_config" ] && [ -f "$workspace/$input_config" ]; then
  config="$workspace/$input_config"
elif [ -f "$workspace/.gitleaks.toml" ]; then
  config="$workspace/.gitleaks.toml"
fi

case "${GITHUB_EVENT_NAME:-}" in
  push)
    range=""
    ;;
  pull_request|pull_request_target)
    range="origin/${GITHUB_BASE_REF:?}..HEAD"
    ;;
  *)
    echo "gitleaks-action: nothing to scan on ${GITHUB_EVENT_NAME:-unknown} events"
    exit 0
    ;;
esac

# The workspace belongs to the runner's user, not the container's.
git config --global --add safe.directory "$workspace"

loads_with_v8() {
  local empty
  empty="$(mktemp -d)"
  gitleaks dir --no-banner --log-level error --config "$1" "$empty" >/dev/null 2>&1
}

if [ -z "$config" ] || loads_with_v8 "$config"; then
  version="$(gitleaks version)"
  cmd=(gitleaks git --no-banner --verbose --redact)
  [ -n "$config" ] && cmd+=(--config "$config")
  [ -n "$range" ] && cmd+=(--log-opts "$range")
  cmd+=("$workspace")
else
  echo "::warning file=${config#"$workspace"/}::gitleaks v8 cannot load this config, so it ran with gitleaks v7, which ignores .gitleaksignore. Migrate it to the gitleaks v8 format (https://github.com/gitleaks/gitleaks#configuration)."
  version="$(gitleaks-v7 --version)"
  cmd=(gitleaks-v7 --path="$workspace" --verbose --redact --config-path="$config")
  if [ -n "$range" ]; then
    git --git-dir="$workspace/.git" log --pretty=format:"%H" "$range" >| /tmp/commit_list.txt
    cmd+=(--commits-file=/tmp/commit_list.txt)
  fi
fi

echo "running gitleaks $version with the following command👇"
echo "${cmd[*]}"
output="$("${cmd[@]}" 2>&1)"
exitcode=$?
echo "$output"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  delimiter="gitleaks-$RANDOM$RANDOM"
  {
    echo "exitcode=$exitcode"
    echo "result<<$delimiter"
    echo "$output"
    echo "$delimiter"
  } >> "$GITHUB_OUTPUT"
fi

echo "----------------------------------"
if [ "$exitcode" -ne 0 ]; then
  echo -e "\e[31m🛑 STOP! Gitleaks encountered leaks (exit code $exitcode)."
  echo "A false positive is allow-listed by adding its Fingerprint line to .gitleaksignore in the repository root."
  exit 1
fi
echo -e "\e[32m✅ SUCCESS! Your code is good to go!"
