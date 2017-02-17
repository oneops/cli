module OO::Cli
  class Command::Transition::Component < Command::Base
    def option_parser
      OptionParser.new do |opts|
        opts.on('-p', '--platform PLATFORM', 'Platform name') { |p| Config.set_in_place(:platform, p)}
        opts.on('-c', '--component COMPONENT', 'Component name') { |c| Config.set_in_place(:component, c)}
        opts.on('-d', '--sibling_depends C1[,C2[,...]]', Array, 'Dependence to other sibling components (i.e. of the same type)') { |sd|  b@sibling_depends = sd}
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
        attr, value = a.split('=', 2)
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

    def scale(*args)
      component = OO::Api::Transition::Component.find(Config.assembly, Config.environment, Config.platform, Config.component)
      data = component.depends_on
      if args.length > 1
        to_ci = args[0]
        unless data[to_ci]
          say "#{'Failed:'.yellow}\n   Target '#{to_ci}' not found."
          return
        end
        attrs = args[1..-1].inject({}) do |h, a|
          attr, value = a.split('=', 2)
          h[attr] = value
          h
        end

        data = component.update_depends_on(to_ci, attrs)
        if data
          say 'Successfully updated scaling.'.green
          say data.to_pretty
        else
          say "#{'Failed:'.yellow}\n   #{component.errors.join("\n   ")}"
        end
      else
        data = data.slice(args[0]) if args.length == 1
        if data
          say data.to_pretty
        else
          say "#{'Failed:'.yellow}\n   #{data.to_pretty}"
        end
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

Scaling action (update if any scaling attributes passed in, otherwise just displays scaling configuration):
    transition component scale -a <ASSEMBLY> -p <PLATFORM> -c <COMPONENT> <COMPONENT_TO_SCALE> [pct_dpmt=<VALUE>] [current=<VALUE>] [min=<VALUE>] [max=<VALUE>] [step_up=<VALUE>] [step_down=<VALUE>]

Available attributes:

    Varies by component type.

Note:
    Use '_' suffix to 'lock' attribute value in transition ("sticky" assignment) (applicable to 'update' action only).
    For example, here is "lock" assignment:
       oneops transition -a ASSEMBLY variable update some-var_=whatever

    and this one is not:
       oneops transition -a ASSEMBLY variable update some-var=whatever

COMMAND_HELP
    end
  end
end
