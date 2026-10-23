# tilde launcher

`tilde` is a small POSIX shell utility for submitting and approving programs
that can be run by other users. Approved commands remain available under
`/tilde/bin`. This version targets Linux with GNU coreutils, `runuser`,
`timeout`, `flock`, `getent`, `sha256sum`, and a sendmail-compatible MTA.

## Commands

```text
tilde list                 Show published scripts
tilde about <script>       Show its description and author
tilde submit               Submit ~/bin/<script>
tilde update <script>      Submit a new revision of your published script
tilde pending              List your submissions awaiting review
tilde status <script>      Display approval status
tilde run <script> [args]  Run an approved script with arguments
sudo tilde approve        Inspect and approve submitted scripts
sudo tilde revoke <name>  Revoke an approved script
sudo tilde migrate [name] Review and migrate legacy approvals
sudo tilde init           Create and secure storage directories
```

`description` is an alias for `about`. Previously published scripts continue
to work from `/tilde/bin` without the wrapper. Add that directory to `PATH` to
run them directly.

## How approvals work

New submissions are **copies** of an executable in the user's `~/bin`, not
symlinks to live code. The submitted file and description remain user-writable;
they are not considered trusted approval state. The administrator captures
both files **under the submitter's UID** in a private review directory, sees
the exact snapshot, and approves that snapshot. No submitted program is
executed during approval.

Approved files are stored in root-owned `/tilde/approved/<name>/<sha256>`.
`/tilde/bin/<name>` points to the approved version. Approval records live in
root-owned `/tilde/metadata`; rejected submission fingerprints are tracked in
`/tilde/rejected`. Published descriptions remain in
`/tilde/descriptions`. Previous versions are retained without ordinary user
read/execute permissions after an update or revocation. Each approval/revocation
is also sent to syslog with the tag `tilde-launcher`.

An administrator can approve, reject (with a reason sent to the author), or
skip a submission. A rejected submission may be replaced with `tilde submit`.

A submission is limited to 50 MiB with a 16 KiB description. Single-file
scripts and executables work best. Scripts that load adjacent assets or rely on
`dirname "$0"` may require an adjusted wrapper or an app-specific packaging
approach; do not migrate those without checking them first.

## Installing or upgrading

```sh
git clone https://github.com/tildeclub/launcher.git
cd launcher
sh tests/smoke.sh
sudo make install
sudo tilde init
```

Review existing `/tilde` ownership and permissions before running `init`.
It refuses pre-existing, unsafe symlink directories and group/world-writable
administrative directories instead of silently overwriting them. The parent
`/tilde/pending-submissions` is set to sticky mode `1733`; existing user
submissions are not deleted. `/tilde/review` is root-only (`0700`).

**Important:** `make install` does not replace any previously approved
`/tilde/bin` symlinks. They remain live links to user code until explicitly
migrated. Administrators should plan a manual review:

```sh
sudo tilde migrate               # review each legacy link
sudo tilde migrate some-script   # or migrate one at a time
```

A migration checks the target is under its owner's home `bin` directory,
captures it under the author's UID, and asks for approval. Existing users'
source files are not modified. If a legacy symlink relies on adjacent files,
leave it untouched until it has a suitable standalone replacement.

Do **not** point `/tilde/approved`, `/tilde/metadata`, `/tilde/rejected`, or `/tilde/review` at
user-controlled storage. The administrative directories must be root-owned,
not symlinks, and not writable by other users. `runuser`, `timeout`, and `flock`
are required for approval and migration. A working `/usr/sbin/sendmail` is
recommended for notices; failure to send mail is reported without undoing a
completed submission or approval.

To verify the deployment:

```sh
sudo tilde init
tilde --version
tilde list
tilde status some-script
sudo journalctl -t tilde-launcher --since today
```

For an optional full test on an isolated test machine or CI runner, execute
`sudo sh tests/integration.sh`. It creates and removes a temporary system
account and tests under `/tmp`, without using your live `/tilde` tree.

## Broken legacy entries

`sudo tilde migrate` now continues past broken links, reports each one, and returns
an error status if it skipped an unreadable or broken target. The links are not
removed automatically. For an affected command, inspect the link and its
submitted file without following or deleting anything:

```sh
sudo tilde status us
sudo ls -ld /tilde/bin/us /tilde/pending-submissions/jmjl/us
sudo readlink -- /tilde/bin/us
sudo ls -l /tilde/pending-submissions/jmjl/us
```

The `us` and `jmjl` names above are examples. If the linked executable was
moved or deleted, restore it under the author's `~/bin` and review it again.
If the source is gone permanently, the administrator can explicitly run
`sudo tilde revoke us`, confirm, and provide a reason. A broken legacy link
whose author cannot be identified can now be revoked, but no email will be
sent. There is no automatic deletion during migration. Old
submissions containing broken executable symlinks are skipped with a specific
warning, without stopping approval of other submissions.

Root-owned legacy per-user pending directories can be read during approval
when they are not group/world writable. New submissions still require the
user's own pending directory to be owned by that user. Do not recursively
change ownership or permissions of `/tilde` to fix a single submission.

## Recovery and rollback

Before installing, archive `/tilde` and preserve the old launcher binary and
manual page. Because existing approvals are not migrated automatically,
reverting the command alone restores its original behaviour for unmigrated
scripts. Migrated scripts are immutable copies; reverting to the old launcher
does **not** restore the old user-owned symlinks. Restore the corresponding
`/tilde/bin` links, descriptions, and metadata from the backup if you need to
undo a migration. Avoid restoring old files over an active installation without
first stopping administrative changes.

## Development

```sh
sh tests/smoke.sh
sudo sh tests/integration.sh  # isolated test, needs root and useradd
```

Please run ShellCheck and test on a non-production machine before deploying.
No GitHub commit or migration occurs merely by applying a patch.
