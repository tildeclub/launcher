# `envs` - user script envs-launcher

forked from [tilde](https://tildegit.org/team/tilde-launcher)

```
wrapper for user-submitted scripts
supports user submission and admin approval

usage: envs [help|list|submit|about|<script_name>]

  envs list                 - show a list of approved userscripts
  envs submit               - start the submission flow for your own script
  envs about <script_name>  - get the description for script_name
  envs <script_name>        - run script_name with all remaining args are passed to the script
```

approved scripts are placed in /envs/bin and listed with `envs list`

submissions use sendmail to notify an admin.

admins can use `sudo envs approve` and `sudo envs revoke <script_name>`.
