module OO::Cli
  class Command::Design::Component < Command::Base

    def option_parser
      OptionParser.new do |opts|
        opts.on('-p', '--platform PLATFORM', 'Platform name') { |p| Config.set_in_place(:platform, p)}
        opts.on('-c', '--component COMPONENT', 'Component name') { |c| Config.set_in_place(:component, c)}
        opts.on('-t', '--type TYPE', 'Component type (e.g. "build", "compute", etc.)') { |t| @type = t}
        opts.on('-d', '--sibling_depends C1[,C2[,...]]', Array, 'Dependence to other sibling components (i.e. of the same type)') { |sd|  @sibling_depends = sd}
      end
    end

    def help(*args)
      display <<-COMMAND_HELP
Usage:
   oneops design component

   Management of components in design.

#{options_help}

Available actions:

    design component list   -a <ASSEMBLY> -p <PLATFORM>
    design component show   -a <ASSEMBLY> -p <PLATFORM> -c <COMPONENT>
    design component open   -a <ASSEMBLY> -p <PLATFORM> -c <COMPONENT>
    design component create -a <ASSEMBLY> -p <PLATFORM> -c <COMPONENT> -t <TYPE> [<attribute>=<VALUE> [<attribute>=<VALUE> ...]] [-l <C1>[,<C2>[,...]]]
    design component update -a <ASSEMBLY> -p <PLATFORM> -c <COMPONENT> [<attribute>=<VALUE> [<attribute>=<VALUE> ...]] [-l <C1>[,<C2>[,...]]]
    design component delete -a <ASSEMBLY> -p <PLATFORM> -c <COMPONENT>

Available attributes:

    Varies by component type.

COMMAND_HELP
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

      if action == :create && @type.blank?
        say 'Please specify component type!'.red
        return false
      end

      return true
    end

    def default(*args)
      Config.component.present? ? show(*args) : list(*args)
    end

    def list(*args)
      components = OO::Api::Design::Component.all(Config.assembly, Config.platform)
      say components.to_pretty
    end

    def show(*args)
      component = OO::Api::Design::Component.find(Config.assembly, Config.platform, Config.component)
      say component.to_pretty
    end

    def open(*args)
      component = OO::Api::Design::Component.find(Config.assembly, Config.platform, Config.component)
      open_ci(component.ciId)
    end

    def create(*args)
      attributes = args.inject({}) do |attrs, a|
        attr, value = a.split('=', 2)
        attrs[attr] = value if attr && value
        attrs
      end
      component = OO::Api::Design::Component.build(Config.assembly, Config.platform, @type)
      component.sibling_depends_on = @sibling_depends
      component.ciName = Config.component
      component.ciAttributes.merge!(attributes)
      if component.save
        say component.to_pretty
      else
        say "#{'Failed:'.yellow}\n   #{component.errors.join("\n   ")}"
      end

    end

    def update(*args)
      component = OO::Api::Design::Component.find(Config.assembly, Config.platform, Config.component)
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

    def delete(*args)
      component = OO::Api::Design::Component.find(Config.assembly, Config.platform, Config.component)
      say "#{'Failed:'.yellow}\n   #{component.errors.join("\n   ")}" unless component.destroy
    end
  end
end
