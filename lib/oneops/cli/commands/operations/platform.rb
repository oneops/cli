module OO::Cli
  class Command::Operations::Platform < Command::Base
    def option_parser
      OptionParser.new do |opts|
        opts.on('-p', '--platform PLATFORM', 'Platform name') { |a| Config.set_in_place(:platform, a)}
      end
    end

    def help(*args)
      display <<-COMMAND_HELP
Usage:
   oneops operations platform

   Management of platforms in operations.

#{options_help}

Available actions:

    operations platform list -a <ASSEMBLY> -e <ENVIRONMENT>
    operations platform show -a <ASSEMBLY> -e <ENVIRONMENT> -p <PLATFORM>

COMMAND_HELP
    end

    def validate(action, *args)
      unless action == :default || action == :list || Config.platform.present?
        say 'Please specify platform!'.red
        return false
      end

      return true
    end

    def default(*args)
      Config.platform.present? ? show(*args) : list(*args)
    end

    def list(*args)
      platforms = OO::Api::Operations::Platform.all(Config.assembly, Config.environment)
      say platforms.to_pretty( :title => Config.assembly )
    end

    def show(*args)
      platform = OO::Api::Operations::Platform.find(Config.assembly, Config.environment, Config.platform)
      say platform.to_pretty
    end

  end
end
