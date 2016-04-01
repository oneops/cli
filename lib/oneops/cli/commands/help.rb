module OO::Cli::Command
  class Help < Base
    skip_configure_api

    def process(*args)
      if args.size == 0
        display <<-USAGE
Usage:

  oneops|oo [options] command [<args>] [command_options]

#{OO::Cli::Runner::OPTION_PARSER}

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
USAGE

      else
        begin
          cmd = args.shift
          OO::Cli::Command.const_get(cmd.capitalize).new.send(:help, *args)
        rescue NameError => e
          say "Unknown command [#{cmd}]".red
        end
      end
    end
  end
end
