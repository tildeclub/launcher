#!/bin/sh
# Full test of the approval path. Requires root, runuser, and getent.
set -eu
[ "$(id -u)" -eq 0 ] || { echo 'Run as root' >&2; exit 1; }
for cmd in runuser timeout flock sha256sum getent; do
    command -v "$cmd" >/dev/null || { echo "Missing $cmd" >&2; exit 1; }
done
cd "$(dirname "$0")/.."
tmp=$(mktemp -d /tmp/tilde-launcher-test.XXXXXXXX)
user=launcher-test-$$
cleanup() {
    userdel "$user" >/dev/null 2>&1 || :
    rm -rf "$tmp"
}
trap 'cleanup' EXIT HUP INT TERM
chmod 0755 "$tmp"
root=$tmp/tilde
home=$tmp/home
useradd -M -d "$home" -s /bin/sh "$user"
uid=$(id -u "$user")
gid=$(id -g "$user")
mkdir -m 0755 "$home"
mkdir -m 0755 "$home/bin"
chown -R "$uid:$gid" "$home"
cat > "$tmp/sendmail" <<'EOF'
#!/bin/sh
cat >/dev/null
EOF
chmod 0755 "$tmp/sendmail"
sed -e "s|^ROOT=/tilde$|ROOT=$root|" \
    -e "s|/usr/sbin/sendmail|$tmp/sendmail|g" tilde > "$tmp/launcher"
chmod 0755 "$tmp/launcher"
"$tmp/launcher" init >/dev/null
cat > "$home/bin/example" <<'EOF'
#!/bin/sh
printf 'v1:%s\n' "$*"
EOF
chmod 0755 "$home/bin/example"
chown "$uid:$gid" "$home/bin/example"
printf 'y\nexample\nA test script\ny\n' |
    runuser -u "$user" -- env HOME="$home" "$tmp/launcher" submit >/dev/null
printf 'a\n' | "$tmp/launcher" approve >/dev/null
[ "$("$tmp/launcher" run example argument)" = 'v1:argument' ]
[ "$("$tmp/launcher" about example | head -n 1)" = 'A test script' ]
# Changing the user's script cannot change what everyone else executes.
cat > "$home/bin/example" <<'EOF'
#!/bin/sh
printf 'v2:%s\n' "$*"
EOF
chmod 0755 "$home/bin/example"
chown "$uid:$gid" "$home/bin/example"
[ "$("$tmp/launcher" run example argument)" = 'v1:argument' ]
printf 'Updated description\ny\ny\n' |
    runuser -u "$user" -- env HOME="$home" "$tmp/launcher" update example >/dev/null
printf 'a\n' | "$tmp/launcher" approve >/dev/null
[ "$("$tmp/launcher" run example argument)" = 'v2:argument' ]
# The retired version is not executable by ordinary users.
# Verify the old version's permissions without making any assumptions about its hash.
for previous in "$root/approved/example"/*; do
    [ -f "$previous" ] || continue
    if [ "$(readlink -f "$root/bin/example")" != "$previous" ]; then
        [ "$(stat -c %a "$previous")" = 700 ]
    fi
done
# Cancellation must not revoke anything.
printf 'n\n' | "$tmp/launcher" revoke example >/dev/null
[ -x "$root/bin/example" ]
printf 'y\nSecurity review\n' | "$tmp/launcher" revoke example >/dev/null
[ ! -e "$root/bin/example" ] && [ ! -L "$root/bin/example" ]
[ "$(stat -c %a "$(find "$root/approved/example" -maxdepth 1 -type f | tail -n 1)")" = 700 ]
# Reject a submission, then allow a corrected resubmission.
cat > "$home/bin/rejected" <<'EOF'
#!/bin/sh
echo rejected-v1
EOF
chmod 0755 "$home/bin/rejected"
chown "$uid:$gid" "$home/bin/rejected"
printf 'y\nrejected\nFirst version\ny\n' |
    runuser -u "$user" -- env HOME="$home" "$tmp/launcher" submit >/dev/null
printf 'r\nNeeds revision\n' | "$tmp/launcher" approve >/dev/null
[ ! -e "$root/bin/rejected" ]
runuser -u "$user" -- env HOME="$home" "$tmp/launcher" status rejected | grep -q 'rejected'
printf 'y\nrejected\nFixed version\ny\ny\n' |
    runuser -u "$user" -- env HOME="$home" "$tmp/launcher" submit >/dev/null
printf 'a\n' | "$tmp/launcher" approve >/dev/null
[ "$("$tmp/launcher" run rejected)" = 'rejected-v1' ]
# Migrating a legacy symlink requires review and freezes the code.
cat > "$home/bin/legacy" <<'EOF'
#!/bin/sh
echo legacy-v1
EOF
chmod 0755 "$home/bin/legacy"
chown "$uid:$gid" "$home/bin/legacy"
ln -s "$home/bin/legacy" "$root/bin/legacy"
printf 'A legacy script\n' > "$root/descriptions/legacy"
printf 'a\n' | "$tmp/launcher" migrate legacy >/dev/null
[ "$("$tmp/launcher" run legacy)" = 'legacy-v1' ]
printf '#!/bin/sh\necho legacy-v2\n' > "$home/bin/legacy"
[ "$("$tmp/launcher" run legacy)" = 'legacy-v1' ]
printf 'Integration tests passed.\n'
# A broken legacy symlink must not stop migration of subsequent entries.
ln -s "$home/bin/missing-us" "$root/bin/us"
printf 'Missing script\n' > "$root/descriptions/us"
cat > "$home/bin/zzgood" <<'EOF_INNER'
#!/bin/sh
echo zzgood-v1
EOF_INNER
chmod 0755 "$home/bin/zzgood"
chown "$uid:$gid" "$home/bin/zzgood"
ln -s "$home/bin/zzgood" "$root/bin/zzgood"
printf 'Good legacy script\n' > "$root/descriptions/zzgood"
if printf 'a\n' | "$tmp/launcher" migrate > "$tmp/migrate.out" 2> "$tmp/migrate.err"; then
    echo 'Expected batch migration to report a broken legacy link' >&2
    exit 1
fi
grep -q 'broken legacy symlink: us' "$tmp/migrate.err"
grep -q 'migration finished with 1 unreadable or broken link' "$tmp/migrate.err"
[ -L "$root/bin/us" ] && [ ! -e "$root/bin/us" ]
[ "$("$tmp/launcher" run zzgood)" = zzgood-v1 ]
"$tmp/launcher" status us | grep -q 'broken or inaccessible'
# Root-owned legacy submission directories may be reviewed read-only.
# Broken submitted symlinks must give actionable diagnostics, not abort the queue.
chown root:root "$root/pending-submissions/$user"
chmod 0755 "$root/pending-submissions/$user"
mkdir -m 0755 "$root/pending-submissions/$user/us"
ln -s "$home/bin/missing-us" "$root/pending-submissions/$user/us/us"
printf 'Broken old submission\n' > "$root/pending-submissions/$user/us/description.txt"
cat > "$home/bin/legacypending" <<'EOF_INNER'
#!/bin/sh
echo reviewed-legacy-pending
EOF_INNER
chmod 0755 "$home/bin/legacypending"
chown "$uid:$gid" "$home/bin/legacypending"
mkdir -m 0755 "$root/pending-submissions/$user/legacypending"
ln -s "$home/bin/legacypending" "$root/pending-submissions/$user/legacypending/legacypending"
printf 'An older pending submission\n' > "$root/pending-submissions/$user/legacypending/description.txt"
printf 'a\n' | "$tmp/launcher" approve > "$tmp/approve.out" 2> "$tmp/approve.err"
grep -q "broken submitted-script symlink: $user/us" "$tmp/approve.err"
[ "$("$tmp/launcher" run legacypending)" = reviewed-legacy-pending ]
[ -L "$root/bin/us" ] && [ ! -e "$root/bin/us" ]
# A broken legacy link can be revoked with confirmation, even without its owner.
printf 'n\n' | "$tmp/launcher" revoke us >/dev/null
[ -L "$root/bin/us" ]
printf 'y\nBroken and no longer available\n' | "$tmp/launcher" revoke us >/dev/null 2> "$tmp/revoke.err"
[ ! -L "$root/bin/us" ] && [ ! -e "$root/bin/us" ]
[ ! -e "$root/descriptions/us" ]
grep -q 'author unknown; no notification sent' "$tmp/revoke.err"
