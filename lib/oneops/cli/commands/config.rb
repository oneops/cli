module OO::Cli::Command
  class Config < Base
    skip_configure_api

    def option_parser
      OptionParser.new do |opts|
        opts.on('-g', '--global', 'Global configuration') {@global = true}
        opts.on('-l', '--local',  'Local (current directory) configuration') {@local = true}
      end
    end

    def default(*args)
      list(*args)
    end

    def validate(action, *args)
      if action == :set || action == :clear
        unless @global || @local
          say "Please specify 'global' or 'local' option.".red
          return false
        end
      end
      return true
    end

    def list(*args)
      data = if @global
        OO::Cli::Config.global
      elsif @local
        OO::Cli::Config.local
      else
        OO::Cli::Config.data
      end
      say data.to_yaml if data.size > 0
    end

    def set(*args)
      args.each do |a|
        key, value = a.split('=', 2)
        OO::Cli::Config.set(key, value, @global) if key && value
      end
    end

    def clear(*args)
      args.each do |a|
        OO::Cli::Config.clear(a, @global)
      end
    end

    def help(*args)
      display <<-COMMAND_HELP
Usage:
   oneops config

   Management of global and local (by directory) configuration settings and default command parameters.

#{options_help}


Available actions:

    config list [-g|-l]
    config set <param_or_setting>=<VALUE> [<param_or_setting>=<VALUE> ...] -g|-l
    config clear <param_or_setting> [<param_or_setting> ...] -g|-l


Required settings:

    site         OneOps site url
    user         OneOps user ID (login name)


Optional settings:

    insecure     Set to 'true' to skip SSL verification (not SSL certificate validation).
    timing       Set to 'true' to display command execution duration.


Optional parameters:

    organization Current organization
    assembly     Current assembly
    environment  Current environment
    platform     Current platform
    ...

COMMAND_HELP
    end
  end
end
