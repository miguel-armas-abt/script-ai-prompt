#!/bin/bash
set -e

source ./../variables.env
source ./commons.sh

SCRIPT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SEPARATOR=$'\n---\n'
OUTPUT_PROMPT_PATH="$SCRIPT_ROOT/${OUTPUT_PROMPT_FILE#./}"

append_separator() {
  echo "$SEPARATOR" >> "$OUTPUT_PROMPT_PATH"
}

init_output_file() {
  : > "$OUTPUT_PROMPT_PATH"
}

append_analysis_file() {
  local file="$1"

  echo "archivo encontrado: $file"
  [[ -f "$file" ]] || { log "skip (not file): $file"; return; }

  local label="\` /${file#$PROJECT_PATH/}\`"
  echo "$label" >> "$OUTPUT_PROMPT_PATH"
  echo '```' >> "$OUTPUT_PROMPT_PATH"
  cat "$file" >> "$OUTPUT_PROMPT_PATH"
  echo -e '\n```' >> "$OUTPUT_PROMPT_PATH"
}

append_prompt_rules() {
  firstline=true
  while IFS=',' read -r file_name || [ -n "$file_name" ]; do
    # Ignore headers
    if $firstline; then
        firstline=false
        continue
    fi

    # Ignore comments
    if [[ $file_name != "#"* ]]; then
      local abs="$SCRIPT_ROOT/$file_name"
      [[ -f "$abs" ]] || { log "skip (not file): $abs"; continue; }
      cat "$abs" >> "$OUTPUT_PROMPT_PATH"
      append_separator
    fi

  done < <(sed 's/\r//g' "$SCRIPT_ROOT/$INPUT_PROMPT_FILES")
}

append_project_tree() {
  echo '```' >> "$OUTPUT_PROMPT_PATH"
  bash "$SCRIPT_ROOT/src/tree-generator.sh" >> "$OUTPUT_PROMPT_PATH"
  echo '```' >> "$OUTPUT_PROMPT_PATH"
  append_separator
}

append_analysis_path_files() {
  ( cd "$PROJECT_PATH" && find "$ANALISIS_PATH" -type f | LC_ALL=C sort ) | while read -r rel; do
    append_analysis_file "$PROJECT_PATH/$rel"
    append_separator
  done
}

append_extra_analysis_files() {
  firstline=true
  while IFS=',' read -r file_name || [ -n "$file_name" ]; do
    # Ignore headers
    if $firstline; then
        firstline=false
        continue
    fi

    # Ignore comments
    if [[ $file_name != "#"* ]]; then
      append_analysis_file "$PROJECT_PATH/$file_name"
      append_separator
    fi

  done < <(sed 's/\r//g' "$SCRIPT_ROOT/$ANALISIS_EXTRA_FILES")
}

main() {
  init_output_file
  append_prompt_rules
  append_project_tree
  append_analysis_path_files
  append_extra_analysis_files
}

main
