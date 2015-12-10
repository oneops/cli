module OO::Cli
  class Command::Operations::Component < Command::Base
    def option_parser
      OptionParser.new do |opts|
        opts.on('-p', '--platform PLATFORM', 'Platform name') { |p| Config.set_in_place(:platform, p)}
        opts.on('-c', '--component COMPONENT', 'Component name') { |c| Config.set_in_place(:component, c)}
      end
    end

    def default(*args)
      Config.component.present? ? show(*args) : list(*args)
    end

    def list(*args)
      components = OO::Api::Operations::Component.all(Config.assembly, Config.environment, Config.platform)
      say components.to_pretty
    end

    def show(*args)
      component = OO::Api::Operations::Component.find(Config.assembly, Config.environment, Config.platform, Config.component)
      say component.to_pretty
    end
       
    def help(*args)
      display <<-COMMAND_HELP
Usage:
   oneops operations component
   
   Management of components in operations.

#{options_help}

Available actions:

    operations component list -a <ASSEMBLY> -p <PLATFORM>
    operations component show -a <ASSEMBLY> -p <PLATFORM> -c <COMPONENT>

Available attributes:

    Varies by component type.

COMMAND_HELP
    end
  end
end
