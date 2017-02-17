module OO::Cli
  class Command::Transition::Platform < Command::Base
    def option_parser
      OptionParser.new do |opts|
        opts.on('-p', '--platform PLATFORM', 'Platform name') { |a| Config.set_in_place(:platform, a)}
      end
    end

    def help(*args)
      display <<-COMMAND_HELP
Usage:
   oneops transition platform

   Management of platforms in transition.

#{options_help}

Available actions:

    transition platform list   -a <ASSEMBLY> -e <ENVIRONMENT>
    transition platform show   -a <ASSEMBLY> -e <ENVIRONMENT> -p <PLATFORM>
    transition platform enable -a <ASSEMBLY> -e <ENVIRONMENT> -p <PLATFORM>
    transition platform disable -a <ASSEMBLY> -e <ENVIRONMENT> -p <PLATFORM>

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
      platforms = OO::Api::Transition::Platform.all(Config.assembly, Config.environment)
      say platforms.to_pretty( :title => Config.assembly )
    end

    def show(*args)
      platform = OO::Api::Transition::Platform.find(Config.assembly, Config.environment, Config.platform)
      say platform.to_pretty
    end

    def enable(*args)
      platform = OO::Api::Transition::Platform.find(Config.assembly, Config.environment, Config.platform)
      env = OO::Api::Transition::Environment.find(Config.assembly, Config.environment)
      if env.enable([platform.ciId.to_i])
        say 'Successfully enabled platform.'.green
      else
        say "#{'Failed:'.yellow}\n   #{env.errors.join("\n   ")}"
      end
    end

    def disable(*args)
      platform = OO::Api::Transition::Platform.find(Config.assembly, Config.environment, Config.platform)
      env = OO::Api::Transition::Environment.find(Config.assembly, Config.environment)
      if env.disable([platform.ciId.to_i])
        say 'Successfully disabled platform.'.green
      else
        say "#{'Failed:'.yellow}\n   #{env.errors.join("\n   ")}"
      end
    end
  end
end
