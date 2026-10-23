#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
sh -n tilde
[ "$(./tilde --version)" = 0.2.1 ]
./tilde --help | grep -q 'migrate'
if ./tilde run '../etc/passwd' >/dev/null 2>&1; then
    printf 'Path traversal was accepted\n' >&2
    exit 1
fi
if ./tilde revoke '../etc/passwd' >/dev/null 2>&1; then
    printf 'Unsafe revocation was accepted\n' >&2
    exit 1
fi
printf 'Smoke tests passed.\n'
