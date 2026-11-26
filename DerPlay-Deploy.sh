#!/usr/bin/env bash
# Run from the delivery directory. Never update main or force push.
set -euo pipefail
export GIT_PAGER=cat PAGER=cat
repo=https://github.com/personroad/DerPlay.git
work="$HOME/DerPlay-build2-work"
source_dir=$PWD
fail(){ printf 'ERROR: %s\n' "$*" >&2; exit 1; }
shopt -s nullglob
zips=()
for f in DerPlay-*-build*-source.zip; do
  [[ $f =~ ^DerPlay-[0-9]+\.[0-9]+\.[0-9]+-build[1-9][0-9]*-source\.zip$ ]] && zips+=("$f")
done
((${#zips[@]})) || fail 'No versioned source ZIP in current directory.'
zip=$(printf '%s\n' "${zips[@]}" | sort -V | tail -n 1)
[[ $zip =~ ^DerPlay-([0-9]+\.[0-9]+\.[0-9]+)-build([1-9][0-9]*)-source\.zip$ ]] || fail 'Invalid version.'
version=${BASH_REMATCH[1]}; build=${BASH_REMATCH[2]}
[[ $version == 0.0.1 ]] || fail 'Main version change requires explicit approval and updated deployment policy.'
patches=(DerPlay-build*-to-build"$build".patch)
((${#patches[@]} == 1)) || fail 'Expected exactly one matching incremental patch.'
patch=${patches[0]}
[[ $patch =~ ^DerPlay-build([1-9][0-9]*)-to-build([1-9][0-9]*)\.patch$ ]] || fail 'Invalid patch name.'
base=${BASH_REMATCH[1]}
((base < build)) || fail 'Invalid patch base build.'
checksum="DerPlay-${version}-build${build}-SHA256.txt"
[[ -f $checksum ]] || fail "Missing $checksum"
for f in "$zip" "$patch"; do
  expected=$(awk -v n="$f" '$2==n || $2=="*"n {print $1}' "$checksum")
  [[ $expected =~ ^[0-9a-fA-F]{64}$ ]] || fail "Missing or duplicate checksum: $f"
  actual=$(sha256sum -- "$f"); actual=${actual%% *}
  [[ ${expected,,} == "$actual" ]] || fail "Checksum mismatch: $f"
done
branch="build/${version}-build${build}"
basebranch="build/${version}-build${base}"
printf 'DerPlay %s Build %s (base %s)\n%s\n%s\n' "$version" "$build" "$base" "$zip" "$patch"
if [[ ! -d $work/.git ]]; then git clone "$repo" "$work"; fi
cd "$work"
[[ $(git remote get-url origin) == "$repo" ]] || fail 'Unexpected repository remote.'
[[ -z $(git status --porcelain) ]] || fail 'Working tree is not clean.'
git fetch origin
# Read the committed plist, independent of checkout and CRLF.
plist_build(){ git show "$1:App/Info.plist" | awk '/<key>CFBundleVersion<\/key>/{getline; gsub(/<[^>]+>|[[:space:]]/, ""); print; exit}'; }
if git show-ref --verify --quiet "refs/heads/$branch"; then
  git switch "$branch"
  if git show-ref --verify --quiet "refs/remotes/origin/$branch"; then git merge --ff-only "origin/$branch"; fi
elif git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
  git switch -c "$branch" "origin/$branch"
else
  if git show-ref --verify --quiet "refs/remotes/origin/$basebranch" && [[ $(plist_build "origin/$basebranch") == "$base" ]]; then
    ref="origin/$basebranch"
  elif [[ $(plist_build origin/main) == "$base" ]]; then
    ref=origin/main
  else
    fail "No remote base at Build $base; upload the required base first."
  fi
  git switch -c "$branch" "$ref"
fi
patch_path="$source_dir/$patch"
if [[ $(plist_build HEAD) == "$build" ]] && git apply --reverse --check --index "$patch_path"; then
  echo 'Patch already applied.'
else
  [[ $(plist_build HEAD) == "$base" ]] || fail 'Target branch has an unexpected base build.'
  git apply --check --index "$patch_path"
  git apply --index "$patch_path"
  [[ $(plist_build '') == "$build" ]] || fail 'Staged version mismatch; inspect staged changes.'
  git diff --cached --stat
  git commit -m "DerPlay $version Build $build"
fi
[[ $(git branch --show-current) == "$branch" ]] || fail 'Wrong target branch.'
git push -u origin "$branch"
printf 'Uploaded %s; main unchanged.\n' "$branch"
if command -v explorer.exe >/dev/null; then explorer.exe 'https://github.com/personroad/DerPlay/actions' || true; fi
