module OO::Cli
  class Command::Operations::Instance < Command::Base
    def option_parser
      OptionParser.new do |opts|
        opts.on('-p', '--platform PLATFORM', 'Platform name') { |p| Config.set_in_place(:platform, p)}
        opts.on('-c', '--component COMPONENT', 'Component name') { |c| Config.set_in_place(:component, c)}
        opts.on('-i', '--instance INSTANCE', 'Instance name') { |c| Config.set_in_place(:instance, c)}
      end
    end

    def default(*args)
      Config.instance.present? ? show(*args) : list(*args)
    end

    def list(*args)
      instances = OO::Api::Operations::Instance.all(Config.assembly, Config.environment, Config.platform, Config.component)
      say instances.to_pretty
    end

    def show(*args)
      instance = OO::Api::Operations::Instance.find(Config.assembly, Config.environment, Config.platform, Config.component, Config.instance)
      say instance.to_pretty
    end

    def replace(*args)
      instance = OO::Api::Operations::Instance.find(Config.assembly, Config.environment, Config.platform, Config.component, Config.instance)
      if instance.replace
        say instance.to_pretty
      else
        say "#{'Failed:'.yellow}\n   #{instance.errors.join("\n   ")}"
      end
    end

    def unreplace(*args)
      instance = OO::Api::Operations::Instance.find(Config.assembly, Config.environment, Config.platform, Config.component, Config.instance)
      if instance.unreplace
        say instance.to_pretty
      else
        say "#{'Failed:'.yellow}\n   #{instance.errors.join("\n   ")}"
      end
    end
    
    def delete(*args)
      instance = OO::Api::Operations::Instance.find(Config.assembly, Config.environment, Config.platform, Config.component, Config.instance)
      if instance.destroy
        say instance.to_pretty
      else
        say "#{'Failed:'.yellow}\n   #{instance.errors.join("\n   ")}"
      end
    end
           
    def help(*args)
      display <<-COMMAND_HELP
Usage:
   oneops operations instance
   
   Management of instances in operations.

#{options_help}

Available actions:

    operations instance list      -a <ASSEMBLY> -p <PLATFORM> -c <COMPONENT>
    operations instance show      -a <ASSEMBLY> -p <PLATFORM> -c <COMPONENT> -i <INSTANCE>
    operations instance replace   -a <ASSEMBLY> -p <PLATFORM> -c <COMPONENT> -i <INSTANCE>
    operations instance unreplace -a <ASSEMBLY> -p <PLATFORM> -c <COMPONENT> -i <INSTANCE>
    operations instance delete    -a <ASSEMBLY> -p <PLATFORM> -c <COMPONENT> -i <INSTANCE>

Available attributes:

    Varies by instance type.

COMMAND_HELP
    end
  end
end
