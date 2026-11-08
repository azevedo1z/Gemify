#!/usr/bin/env bash
set -euo pipefail

tag="$1"
repository="${GITHUB_REPOSITORY:-azevedo1z/Gemify}"
previous="$(git describe --tags --abbrev=0 "$tag^" 2>/dev/null || true)"
range="$tag"
if [ -n "$previous" ]; then
  range="$previous..$tag"
fi

subjects="$(git log --no-merges --format='%s' "$range" | grep -v '^chore(release)' || true)"

section() {
  local title="$1" types="$2" lines
  lines="$(printf '%s\n' "$subjects" \
    | grep -E "^($types)(\([^)]*\))?!?: " \
    | sed -E 's/^[a-z]+(\([^)]*\))?!: /- **Breaking:** /; s/^[a-z]+(\([^)]*\))?: /- /' \
    || true)"
  if [ -n "$lines" ]; then
    printf '## %s\n\n%s\n\n' "$title" "$lines"
  fi
}

section 'Features' 'feat'
section 'Fixes' 'fix'
section 'Other changes' 'perf|refactor|revert|build|ci|docs|test|style|chore'

if [ -n "$previous" ]; then
  printf '**Full diff:** https://github.com/%s/compare/%s...%s\n' "$repository" "$previous" "$tag"
fi
