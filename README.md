# `tilde` - manage users_info.json entrys and user-submitted scripts

forked from [tilde](https://tildegit.org/team/tilde-launcher)
adding in updates from [envs.net fork](https://git.envs.net/envs/envs_launcher/)

```
wrapper for user-submitted scripts and users_info.json entrys
supports user settings, submission and admin approval

User Scripts

usage: tilde [help|list|submit|about|script_name]
  tilde list                  - show a list of approved userscripts
  tilde submit                - start the submission flow for your own script
  tilde about <script_name>   - get the description for script_name
  tilde <script_name>         - run script_name with all remaining args are passed to the script

User json-File Infomations

usage: tilde [show]|[edit]|[get name]|[set name value]|[unset name]
  tilde show                  - show your config file
  tilde edit                  - edit your config file
  tilde get <entry>           - show a entry from your config
  tilde set <entry> <'value'> - set a entry to your config
  tilde unset <entry>         - unset a entry from your config
```

approved scripts are placed in /tilde/bin and listed with `tilde list`

submissions use sendmail to notify an admin.

admins can use `sudo tilde approve` and `sudo tilde revoke <script_name>`.

users can also manage youre `users_info.json` entrys from the `~/.tilde`-file.

