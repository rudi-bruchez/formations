#!/usr/bin/env bash
# release-notes.sh <version> <owner/repo> [checksums-file] [changelog]
#
# Prints the GitHub release note for <version>: the CHANGELOG.md section of
# that version, a download-and-verify block, and the compare link to the
# previous version. The same file is copied into each of the author's tool
# repositories as scripts/release-notes.sh: change them together.
#
# Reads both heading forms in use: "## [0.5.0] - 2026-10-06" (Keep a Changelog)
# and "## 0.7.0, 13 September 2026". The compare link starts from the nearest
# older version in the file that has a tag on origin (git ls-remote, which a
# shallow checkout can run): a version may have a section and no tag. Without
# access to origin it falls back to the next version heading below.
# RELEASE_NOTES_TAGS, one tag per line, replaces the ls-remote (tests).
# RELEASE_TAG_PREFIX (default "v") is the tag prefix, for a repository that
# releases several tools under prefixed tags (pachaworkload-v1.0.0).
set -eu
version=${1:?usage: release-notes.sh <version> <owner/repo> [checksums-file] [changelog]}
version=${version#v}
repo=${2:?usage: release-notes.sh <version> <owner/repo> [checksums-file] [changelog]}
checksums=${3:-}
changelog=${4:-CHANGELOG.md}
prefix=${RELEASE_TAG_PREFIX:-v}

# One pass: the body of the section, then a line "\x01<older versions, newest first>".
out=$(awk -v want="$version" '
  function headver(line,   s) {
    s = line
    if (match(s, /[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.]+)?/)) return substr(s, RSTART, RLENGTH)
    return ""
  }
  /^## / {
    h = headver($0)
    if (found && h != "" && h != want) older = older " " h
    inside = (h == want)
    if (inside) found = 1
    next
  }
  /^\[[^]]+\]: / { next }      # link reference definitions at the end of the file
  inside { body[++n] = $0 }
  END {
    if (!found) exit 3
    first = 1; while (first <= n && body[first] ~ /^[ \t]*$/) first++
    last = n;  while (last >= first && body[last] ~ /^[ \t]*$/) last--
    if (first > last) exit 4
    for (i = first; i <= last; i++) print body[i]
    printf "\001%s\n", older
  }
' "$changelog") || {
  rc=$?
  case $rc in
    3) echo "$changelog has no section for $version" >&2 ;;
    4) echo "the section for $version in $changelog is empty" >&2 ;;
  esac
  exit 1
}

older=${out##*$'\001'}
if [ -n "${RELEASE_NOTES_TAGS+set}" ]; then
  tags=$RELEASE_NOTES_TAGS
else
  tags=$(git ls-remote --tags origin 2>/dev/null | sed -n 's|.*refs/tags/\([^^]*\)$|\1|p') || tags=
fi
previous=
for v in $older; do
  if [ -z "$tags" ] || printf '%s\n' "$tags" | grep -qxF "$prefix$v"; then previous=$v; break; fi
done
printf '%s\n' "${out%$'\n\001'*}"

if [ -n "$checksums" ]; then
  cat <<NOTES

## Download and verify

Archives for each platform are attached below, with their SHA-256 sums in \`$checksums\`. Download the checksums file next to the archive, then:

\`\`\`sh
sha256sum -c --ignore-missing $checksums          # Linux
shasum -a 256 -c --ignore-missing $checksums      # macOS
\`\`\`

On Windows, \`(Get-FileHash <archive>.zip -Algorithm SHA256).Hash\` must match the line of that archive in \`$checksums\` (case aside).
NOTES
fi

if [ -n "$previous" ]; then
  printf '\nFull changelog: https://github.com/%s/compare/%s%s...%s%s\n' "$repo" "$prefix" "$previous" "$prefix" "$version"
fi
