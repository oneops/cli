module OO::Cli
  class Command::Transition::Component < Command::Base
    def option_parser
      OptionParser.new do |opts|
        opts.on('-p', '--platform PLATFORM', 'Platform name') { |p| Config.set_in_place(:platform, p)}
        opts.on('-c', '--component COMPONENT', 'Component name') { |c| Config.set_in_place(:component, c)}
        opts.on('-d', '--sibling_depends C1[,C2[,...]]', Array, 'Dependence to other sibling components (i.e. of the same type)') { |sd|  @sibling_depends = sd}
      end
    end

    def validate(action, *args)
      unless Config.platform.present?
        say 'Please specify platform!'.red
        return false
      end

      unless action == :default || action == :list || Config.component.present?
        say 'Please specify component!'.red
        return false
      end

      return true
    end

    def default(*args)
      Config.component.present? ? show(*args) : list(*args)
    end

    def list(*args)
      components = OO::Api::Transition::Component.all(Config.assembly, Config.environment, Config.platform)
      say components.to_pretty
    end

    def show(*args)
      component = OO::Api::Transition::Component.find(Config.assembly, Config.environment, Config.platform, Config.component)
      say component.to_pretty
    end


    def update(*args)
      component = OO::Api::Transition::Component.find(Config.assembly, Config.environment, Config.platform, Config.component)
      args.each do |a|
        attr, value = a.split('=')
        component.ciAttributes[attr] = value if attr && value
      end
      component.sibling_depends_on = @sibling_depends
      if component.save
        say component.to_pretty
      else
        say "#{'Failed:'.yellow}\n   #{component.errors.join("\n   ")}"
      end
    end

    def touch(*args)
      component = OO::Api::Transition::Component.find(Config.assembly, Config.environment, Config.platform, Config.component)
      if component.touch
        say component.to_pretty
      else
        say "#{'Failed:'.yellow}\n   #{component.errors.join("\n   ")}"
      end
    end

    def deploy(*args)
      component = OO::Api::Transition::Component.find(Config.assembly, Config.environment, Config.platform, Config.component)
      if component.deploy
        say component.to_pretty
      else
        say "#{'Failed:'.yellow}\n   #{component.errors.join("\n   ")}"
      end
    end
       
    def help(*args)
      display <<-COMMAND_HELP
Usage:
   oneops transition component
   
   Management of components in transition.

#{options_help}

Available actions:

    transition component list   -a <ASSEMBLY> -p <PLATFORM>
    transition component show   -a <ASSEMBLY> -p <PLATFORM> -c <COMPONENT>
    transition component update -a <ASSEMBLY> -p <PLATFORM> -c <COMPONENT> [<attribute>=<VALUE> [<attribute>=<VALUE> ...]] [-l <C1>[,<C2>[,...]]]

Available attributes:

    Varies by component type.

COMMAND_HELP
    end
  end
end
