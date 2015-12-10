module OO::Cli
  class Command::Transition::Variable < Command::Base
    
    def option_parser
      OptionParser.new do |opts|
        opts.on('-p', '--platform PLATFORM', 'Platform name') { |a| Config.set_in_place(:platform, a)}
      end
    end
    
    def validate(action, *args)
      unless action == :default || action == :list || args.size > 0
        say 'Please specify variable name!'.red
        return false
      end

      return true
    end

    def default(*args)
      Config.variable.present? ? show(*args) : list(*args)
    end

    def list(*args)
      variables = OO::Api::Transition::Variable.all(Config.assembly, Config.environment, Config.platform)
      say variables.to_pretty
    end

    def show(*args)
      variable = OO::Api::Transition::Variable.find(Config.assembly, Config.environment, Config.platform, args[0])
      say variable.to_pretty
    end

    def update(*args)
      name, value = args[0].split('=')
      sticky = name.end_with?('_')
      variable = OO::Api::Transition::Variable.find(Config.assembly, Config.environment, Config.platform, sticky ? name[0...-1] : name)
      variable.ciAttributes[sticky ? 'value_' : 'value'] = value
      if variable.save
        say variable.to_pretty
      else
        say "#{'Failed:'.yellow}\n   #{variable.errors.join("\n   ")}"
      end
    end

    def help(*args)
      display <<-COMMAND_HELP
Usage:
   oneops transition variable
   
   Management of variables in transition.

Available actions:

    transition variable list   -a <ASSEMBLY> -e <ENVIRONMENT> [-p <PLATFORM>]
    transition variable show   -a <ASSEMBLY> -e <ENVIRONMENT> [-p <PLATFORM>] <NAME>
    transition variable update -a <ASSEMBLY> -e <ENVIRONMENT> [-p <PLATFORM>] <NAME>=<VALUE>

Note:
    Use '_' suffix for "lock" assignments.  For example, here is "lock" assignment:
      oneops transition -a ASSEMBLY -e ENVIRONMENT variable update variable_=value
    And this one is not:
      oneops transition -a ASSEMBLY -e ENVIRONMENT variable update variable=value

COMMAND_HELP
    end
  end
end
