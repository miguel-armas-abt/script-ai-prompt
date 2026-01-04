#!/bin/bash
set -e

SCRIPT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$SCRIPT_ROOT/variables.env"

cd "$PROJECT_PATH"

is_ignored() {
  local rel="$1"

  firstline=true
  while IFS=',' read -r ig || [ -n "$ig" ]; do
    # Ignore headers
    if $firstline; then
        firstline=false
        continue
    fi

    # Ignore comments
    if [[ $ig != "#"* ]]; then
      [[ -z "$ig" ]] && continue
      [[ "$rel" == "$ig" || "$rel" == "$ig/"* ]] && return 0
    fi

  done < <(sed 's/\r//g' "$SCRIPT_ROOT/$IGNORE_TREE_PATHS")
  return 1
}

print_dir() {
  local dir="$1"
  local prefix="$2"

  local -a dirs files children
  while IFS= read -r name; do
    [[ -z "$name" ]] && continue
    local child="${dir:+$dir/}$name"
    is_ignored "$child" && continue

    if [[ -d "$child" ]]; then
      dirs+=("$name")
    else
      files+=("$name")
    fi
  done < <(ls -1A "${dir:-.}" 2>/dev/null | LC_ALL=C sort)

  children=("${dirs[@]}" "${files[@]}")
  local total="${#children[@]}"

  local i=0
  for name in "${children[@]}"; do
    i=$((i+1))
    local child="${dir:+$dir/}$name"
    local last=false
    [[ "$i" -eq "$total" ]] && last=true

    if $last; then
      echo "${prefix}└── ${name}$([[ -d "$child" ]] && echo "/")"
    else
      echo "${prefix}├── ${name}$([[ -d "$child" ]] && echo "/")"
    fi

    if [[ -d "$child" ]]; then
      if $last; then
        print_dir "$child" "${prefix}    "
      else
        print_dir "$child" "${prefix}│   "
      fi
    fi
  done
}

echo "."
print_dir "" ""
