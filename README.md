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
    gem install oneops

How To
------

```bash
# Set the OneOps site URL
$ oneops config set site=http://localhost:9090 -g

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

    Usage:
      oneops|oo [options] command [<args>] [command_options]


    Available options:

        -d, --debug                      Output debug info
        -f, --format FORMAT              Output format: console, yaml, json or xml (default: console)
            --file FILE                  Read attributes from yaml file.
        -k, --insecure                   Skip SSL validation.
            --no-color                   Do not colorize output
        -o, --organization ORGANIZATION  OneOps organization
        -q, --quiet                      No output
        -s, --site SITE                  OneOps host site URL (default: https://api.oneops.com)
            --duration                   Show command time duration stat.


    Available commands:

      General
      -------
        version             Display OneOps CLI gem version.
        help [<command>]    Display this help or help for a particular command.

      Setup & Configuration
      ---------------------
        config              Set or display global parameters (e.g. login, password, host, default assembly).

      OneOps Management Commands
      --------------------------
        account             Account management.
        organization        Organization management.
        cloud               Cloud management.
        catalog             Catalog management.
        assembly            Assembly management.
        design              Assembly design management.
        transition          Assembly transition management.
        operations          Assmebly operations management.

    For more information about commands try:
       oneops help <command>

Examples
--------

* See help for a 'config' command

   `$  oneops help config`

* Set the default organization

   `$  oneops config set organization=<organization> -g`

* Get list of assemblies in your org

   `$ oneops assembly`

* Set the assembly name

   `$ oneops config set assembly=<assembly> -g`

* Show all components of a platform

   `$ oneops design component show --organization=<organization> --assembly=<assembly> --platform=<platform> --component=<component>`

* Create a design secure variable (relying on default organization and assembly set via 'config' command)

   `$ oo design variable create SOME-VAR=whatever --secure`

* Update and lock (use '_' after the variable name) an environment secure variable (relying on default organization and assembly set via 'config' command)

   `$ oo transition variable update -e ENVIRONMENT-NAME COOL-VAR_=whatever --secure`

* Update and lock (use '_' after the variable name) attribute 'size' of component in transition (relying on default organization and assembly set via 'config' command), use pretty json output.

   `$ oo transition component update size_=M -f pretty_json -e SOME-ENV -p SOME-PLATFORM -c COMPUTE-COMPONENT`
