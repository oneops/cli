module OO::Cli
  class Command::Account < Command::Base
    def option_parser
      OptionParser.new do |opts|
      end
    end

    def default(*args)
      profile(*args)
    end

    def profile(*args)
      OO::Cli::Command::Account::Profile.new.process(*args)
    end

    def organization(*args)
      OO::Cli::Command::Account::Organization.new.process(*args)
    end

    def help(*args)
      subcommand = args.shift
      if subcommand == 'profile'
        OO::Cli::Command::Account::Profile.new.help(*args)
      elsif subcommand == 'organization'
        OO::Cli::Command::Account::Organization.new.help(*args)
      else
        display <<-COMMAND_HELP
Usage:
   oneops account

   Account management.

#{options_help}

Available subcommands:

    account profile ...
    account organization ...

COMMAND_HELP
      end
    end
  end
end
