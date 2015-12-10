module OO::Cli::Command
  class Help < Base
    def process(*args)
      if args.size == 0
        say command_usage
      else
        cmd = OO::Cli::Command.const_get(args.shift.capitalize)
        cmd.new.send(:help, *args)
      end
    end

    def help(*args)
      display <<-COMMAND_HELP
Usage:
    oneops help

    Display oneops CLI help info.
      COMMAND_HELP
    end

    def command_usage
<<-USAGE
Currently available oneops commands are:

  General
  ---------------------
    version             Display OneOps CLI gem version.
    help [<command>]    Display this help or help for a particular command.

  Setup & Configuration
  ---------------------
    config              Set or display global parameters (e.g. login, password, host, default assembly).

  Commands
  ---------------------
    account             Account management.
    organization        Organization management.
    cloud               Cloud management.
    catalog             Catalog management.
    assembly            Assembly management.
    design              Assembly design management.
    transition          Assembly transition management.
    operations          Assmebly operations management.

USAGE
    end
  end
end

# TODO remove this lib, not needed
