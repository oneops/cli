module OO::Cli
  class Command::Design::Variable < Command::Base
    def option_parser
      OptionParser.new do |opts|
        opts.on('-p', '--platform PLATFORM', 'Platform name') { |a| Config.set_in_place(:platform, a)}
      end
    end

    def help(*args)
      display <<-COMMAND_HELP
Usage:
   oneops design variable

   Management of variables in design.

Available actions:

    design variable list   -a <ASSEMBLY> [-p <PLATFORM>]
    design variable show   -a <ASSEMBLY> [-p <PLATFORM>] <NAME>
    design variable open   -a <ASSEMBLY> [-p <PLATFORM>] <NAME>
    design variable create -a <ASSEMBLY> [-p <PLATFORM>] <NAME>=<VALUE>
    design variable update -a <ASSEMBLY> [-p <PLATFORM>] <NAME>=<VALUE>
    design variable delete -a <ASSEMBLY> [-p <PLATFORM>] <NAME>

COMMAND_HELP
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
      variables = OO::Api::Design::Variable.all(Config.assembly, Config.platform)
      say variables.to_pretty
    end

    def show(*args)
      variable = OO::Api::Design::Variable.find(Config.assembly, Config.platform, args[0])
      say variable.to_pretty
    end

    def open(*args)
      variable = OO::Api::Design::Variable.find(Config.assembly, Config.platform, args[0])
      open_ci(variable.ciId)
    end

    def create(*args)
      name, value = args[0].split('=', 2)
      variable = OO::Api::Design::Variable.new(Config.assembly, Config.platform, {:ciName => name, :ciAttributes => {:value => value}})
      if variable.save
        say variable.to_pretty
      else
        say "#{'Failed:'.yellow}\n   #{variable.errors.join("\n   ")}"
      end

    end

    def update(*args)
      name, value = args[0].split('=', 2)
      variable = OO::Api::Design::Variable.find(Config.assembly, Config.platform, name)
      variable.ciAttributes = {:value => value}
      if variable.save
        say variable.to_pretty
      else
        say "#{'Failed:'.yellow}\n   #{variable.errors.join("\n   ")}"
      end
    end

    def delete(*args)
      variable = OO::Api::Design::Variable.find(Config.assembly, Config.platform, args[0])
      if variable.destroy
        say variable.to_pretty
      else
        say "#{'Failed:'.yellow}\n   #{variable.errors.join("\n   ")}"
      end
    end
  end
end
