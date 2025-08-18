# Example plugin: sqlite
# Usage: poly :sqlite 'select 1;' [/path/to/db.sqlite]
poly_can sqlite
poly_run_sqlite() {
  local code="$1"; local db="${2:-:memory:}"
  command -v sqlite3 >/dev/null 2>&1 || { print -u2 "[-] missing sqlite3"; return 127; }
  print -r -- "$code" | sqlite3 -batch -noheader -csv "$db"
}
