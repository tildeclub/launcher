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
