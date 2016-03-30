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

  Management of global and local (by directory) settings and parameters (e.g. user, password, site, default assembly and etc.)

#{options_help}


Available actions:

    config list <options>
    config set <parameter>=<VALUE> [<parameter>=<VALUE> ...] <options>
    config clear <parameter> [<parameter> ...] <options>


Required parameters:

    site         OneOps site url
    user         User ID (login name)
    password     Password (login password)
    organization Your organization

COMMAND_HELP
    end
  end
end
