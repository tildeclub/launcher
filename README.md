# `tilde` - user script tilde-launcher

```
Usage: tilde [options] [command]

Options:
  -h, --help         Show this help message and exit
  -v, --version      Show version information

Commands:
  list               Show a list of approved user scripts
  submit             Start the submission flow for your own script
  about <script>     Show description and details of a specific script
  approve            Enter the approval queue for pending scripts (requires root)
  revoke <script>    Revoke a previously approved script (requires root)
  run <script>       Run an approved script

Please add /tilde/bin to your PATH to use approved scripts without this wrapper.
```

approved scripts are placed in /tilde/bin and listed with `tilde list`

submissions use sendmail to notify an admin.

admins can use `sudo tilde approve` and `sudo tilde revoke <script_name>`.
