OneOps CLI
==========

The OneOps CLI is used to manage OneOps assemblies from the command line. It is implemented as a ruby gem which uses
the [OneOps Restful API](http://oneops.github.io/developer/references/#oneops-api-documentation). Follow the steps below
to install the CLI and login. Enter your API token as username and set the password to 'X'.  You can retrieve your API
token from the [account profile](https://localhost:9090/account/profile#authentication) in the UI.  The credentials are
stored in `~/.netrc`, global config in `~/.oneops` and local config in `.oneops` in current working directory.
For more about OneOps see <http://www.oneops.com>.

Pre-requisites
--------------

The version of Ruby recommended to run the OneOps CLI is [RVM](http://rvm.io) with latest ruby `v1.9.3` installed from there.


Install
-------

    gem build oneops.gemspec
    sudo gem install oneops

How To
------

```bash
# Set the OneOps site URL
$ oneops config set site=https://localhost:9090 -g

$ oneops auth login
Enter your OneOps credentials.
Username: <Auth token>
Password (typing will be hidden):

# Set your OneOps organization
$ oneops config set organization=<organization> -g
# Set the default format
$ oneops config set format=json -g
```


Help
----

    $ oneops
    Usage:
       oneops [options] command [<args>] [command_options]


    Available options:

        -d, --debug                      Output debug info
        -f, --format FORMAT              Output format: console, yaml, json or xml (default: console)
        -q, --quiet                      No output
        -s, --site SITE                  OneOps host site URL (default: https://api.oneops.com)
        -o, --organization ORGANIZATION  OneOps organization
        -R, --raw-output                 Output raw json from API response
            --file FILE                  Read attributes from  yaml file.
            --no-color                   Do not colorize output


    Available commands:

       version             Display OneOps CLI gem version.
       help [command>]     Display this help or help for a particular command.
       config              Set or display global parameters (e.g. login, password, host, default assembly).

       account             Account management.
       organization        Organization management.

       catalog             Catalog management.
       assembly            Assembly management.
       design              Design management.
       transition          Transition management.

    For more information about commands try:
       oneops help [command]

Examples
--------

* Get list of assemblies in your org

   `$ oneops assembly`

* Set the organization

   `$  oneops config set organization=<organization> -g`

* Set the assembly name

   `$ oneops config set assembly=<assembly> -g`

* Show all components of a platform

  `$ oneops design component show --organization=<organization> --assembly=<assembly> --platform=<platform> --component=<component>`
