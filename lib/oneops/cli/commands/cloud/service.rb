module OO::Cli
  class Command::Cloud::Service < Command::Base
    def option_parser
      OptionParser.new do |opts|
        opts.on('-i', '--service SERVICE', 'Service name') { |p| Config.set_in_place(:service, p)}
      end
    end

    def validate(action, *args)
      unless Config.cloud.present?
        say 'Please specify cloud!'.red
        return false
      end

      unless action == :default || action == :list || action == :sources || Config.service.present?
        say 'Please specify service!'.red
        return false
      end

      return true
    end

    def default(*args)
      Config.service.present? ? show(*args) : list(*args)
    end

    def list(*args)
      services = OO::Api::Cloud::Service.all(Config.cloud)
      say services.to_pretty
    end

    def show(*args)
      service = OO::Api::Cloud::Service.find(Config.cloud, Config.service)
      say service.to_pretty
    end

    def create(*args)
      attributes = args.inject({}) do |attrs, a|
        attr, value = a.split('=')
        attrs[attr] = value if attr && value
        attrs
      end
      sources = OO::Api::Cloud::Service.sources(Config.cloud).values.inject([]) {|a, ss| a + ss}
      source = sources.find {|s| s['ciName'] == Config.service }
      unless source
        say "Unknown service source #{Config.service.yellow}!".red
        return
      end

      service = OO::Api::Cloud::Service.build(Config.cloud, source)
      service.ciName = Config.service
      service.ciAttributes.merge!(attributes)
      if service.save
        say service.to_pretty
      else
        say "#{'Failed:'.yellow}\n   #{service.errors.join("\n   ")}"
      end

    end

    def update(*args)
      source = OO::Api::Cloud::Service.find(Config.cloud, Config.service)
      args.each do |a|
        attr, value = a.split('=')
        source.ciAttributes[attr] = value if attr && value
      end
      if source.save
        say source.to_pretty
      else
        say "#{'Failed:'.yellow}\n   #{source.errors.join("\n   ")}"
      end
    end

    def delete(*args)
      source = OO::Api::Cloud::Service.find(Config.cloud, Config.service)
      say "#{'Failed:'.yellow}\n   #{source.errors.join("\n   ")}" unless source.destroy
    end

    def sources(*args)
      say OO::Api::Cloud::Service.sources(Config.cloud).to_pretty
    end

    def help(*args)
      display <<-COMMAND_HELP
Usage:
   oneops cloud service

   Management of cloud services..

#{options_help}

Available actions:

    cloud service list    -c <CLOUD>
    cloud service show    -c <CLOUD> -i <SERVICE>
    cloud service create  -c <CLOUD> -i <SOURCE> [<attribute>=<VALUE> [<attribute>=<VALUE> ...]]
    cloud service update  -c <CLOUD> -i <SERVICE> [<attribute>=<VALUE> [<attribute>=<VALUE> ...]]
    cloud service delete  -c <CLOUD> -i <SERVICE>
    cloud service sources -c <CLOUD>

Available attributes:

    Varies by service type.

COMMAND_HELP
    end
  end
end
