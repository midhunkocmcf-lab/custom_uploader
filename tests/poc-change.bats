#\!/usr/bin/env bats
# Framework: bats-core (Bash Automated Testing System)
# Purpose: Replace placeholder content with actionable tests.
# Scope: Since the diff only touched this file, tests focus on repository shell hygiene
#        and assert the placeholder text is removed.

setup() {
  REPO_ROOT="$(pwd)"
}

teardown() {
  true
}

# Helpers
list_sh_files() {
  find "$REPO_ROOT" -type f -name '*.sh' 2>/dev/null
}

list_candidate_scripts() {
  find "$REPO_ROOT" -type f \( -path "$REPO_ROOT/bin/*" -o -path "$REPO_ROOT/scripts/*" -o -name '*.sh' \) 2>/dev/null
}

@test "sanity: Bats runs commands and captures output" {
  run bash -c 'printf "ok"'
  [ "$status" -eq 0 ]
  [ "$output" = "ok" ]
}

@test "file: tests/poc-change.bats has correct shebang" {
  first_line="$(head -n1 "$BATS_TEST_FILENAME" || true)"
  [ "$first_line" = "#\!/usr/bin/env bats" ]
}

@test "repo: placeholder gibberish removed" {
  # Ensures the nonsensical string from the diff is no longer present anywhere
  run bash -lc 'grep -R -n "abc.etsfsdrfeswrsdfdsfds" .'
  [ "$status" -ne 0 ]
}

@test "scripts: all *.sh files have valid bash syntax" {
  sh_files=()
  while IFS= read -r -d '' f; do sh_files+=("$f"); done < <(find "$REPO_ROOT" -type f -name '*.sh' -print0 2>/dev/null)

  if [ "${#sh_files[@]}" -eq 0 ]; then
    skip "No .sh files found to check."
  fi

  for f in "${sh_files[@]}"; do
    run bash -n "$f"
    if [ "$status" -ne 0 ]; then
      echo "Syntax check failed for: $f"
      echo "$output"
      return 1
    fi
  done
}

@test "scripts: candidate scripts have a shebang" {
  scripts=()
  while IFS= read -r -d '' f; do scripts+=("$f"); done < <(find "$REPO_ROOT" -type f \( -path "$REPO_ROOT/bin/*" -o -path "$REPO_ROOT/scripts/*" -o -name '*.sh' \) -print0 2>/dev/null)

  if [ "${#scripts[@]}" -eq 0 ]; then
    skip "No candidate scripts found."
  fi

  for f in "${scripts[@]}"; do
    two_bytes="$(head -c 2 "$f" || true)"
    if [ "$two_bytes" \!= '#\!' ]; then
      echo "Missing shebang in: $f"
      return 1
    fi
  done
}

@test "lint: shellcheck errors are absent (if shellcheck available)" {
  if \! command -v shellcheck >/dev/null 2>&1; then
    skip "shellcheck not installed."
  fi

  scripts=()
  while IFS= read -r -d '' f; do scripts+=("$f"); done < <(find "$REPO_ROOT" -type f \( -path "$REPO_ROOT/bin/*" -o -path "$REPO_ROOT/scripts/*" -o -name '*.sh' \) -print0 2>/dev/null)

  if [ "${#scripts[@]}" -eq 0 ]; then
    skip "No scripts to lint."
  fi

  for f in "${scripts[@]}"; do
    run shellcheck -S error -e SC1091 "$f"
    if [ "$status" -ne 0 ]; then
      echo "shellcheck errors in: $f"
      echo "$output"
      return 1
    fi
  done
}