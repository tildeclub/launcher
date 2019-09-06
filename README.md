# `envs` - manage users_info.json entrys and user-submitted scripts

forked from [tilde](https://tildegit.org/team/tilde-launcher)

```
wrapper for user-submitted scripts and users_info.json entrys
supports user settings, submission and admin approval

User Scripts

usage: envs [help|list|submit|about|script_name]
  envs list                  - show a list of approved userscripts
  envs submit                - start the submission flow for your own script
  envs about <script_name>   - get the description for script_name
  envs <script_name>         - run script_name with all remaining args are passed to the script

User json-File Infomations

usage: envs [show]|[edit]|[get name]|[set name value]|[unset name]
  envs show                  - show your config file
  envs edit                  - edit your config file
  envs get <entry>           - show a entry from your config
  envs set <entry> <'value'> - set a entry to your config
  envs unset <entry>         - unset a entry from your config
```

approved scripts are placed in /envs/bin and listed with `envs list`

submissions use sendmail to notify an admin.

admins can use `sudo envs approve` and `sudo envs revoke <script_name>`.

users can also manage youre `users_info.json` entrys from the `~/.envs`-file.
