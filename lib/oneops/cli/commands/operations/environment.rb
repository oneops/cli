module OO::Cli
  class Command::Operations::Environment < Command::Base
    def option_parser
      OptionParser.new do |opts|
        opts.on('-e', '--environment ENVIRONMENT', 'Environment name') { |e| Config.set_in_place(:environment, e)}
      end
    end

    def validate(action, *args)
      unless action == :default || action == :list || Config.environment.present?
        say 'Please specify environment!'.red
        return false
      end

      if action == :create
        if @clouds.blank?
          say 'Please specify cloud binding(s)!'.red
          return false
        end
      end

      return true
    end

    def default(*args)
      Config.environment.present? ? show(*args) : list(*args)
    end

    def list(*args)
      envs = OO::Api::Operations::Environment.all(Config.assembly)
      say envs.to_pretty
    end

    def show(*args)
      env = OO::Api::Operations::Environment.find(Config.assembly, Config.environment)
      say env.to_pretty
    end

    def help(*args)
      display <<-COMMAND_HELP
Usage:
   oneops operations environment

   Management of environments in operations.

#{options_help}

Available actions:

    operations environment list    -a <ASSEMBLY>
    operations environment show    -a <ASSEMBLY> -e <ENVIRONMENT>

Available attributes:


COMMAND_HELP
    end
  end
end
