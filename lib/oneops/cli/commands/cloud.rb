module OO::Cli
  class Command::Cloud < Command::Base
    def option_parser
      OptionParser.new do |opts|
        opts.on('-c', '--cloud CLOUD', 'Cloud name') { |a| Config.set_in_place(:cloud, a)}
      end
    end

    def validate(action, *args)
      unless action == :default || action == :list || action == :locations || Config.cloud.present?
        say 'Please specify cloud!'.red
        return false
      end

      return true
    end

    def default(*args)
      Config.cloud ? show(*args) : list(*args)
    end

    def list(*args)
      assemblies = OO::Api::Cloud::Cloud.all
      say assemblies.to_pretty
    end

    def show(*args)
      cloud = OO::Api::Cloud::Cloud.find(Config.cloud)
      say cloud.to_pretty
    end

    def create(*args)
      attributes = args.inject({}) do |attrs, a|
        attr, value = a.split('=', 2)
        if attr && value
          attrs[attr] = value
          if attr == 'location'
            loc = OO::Api::Cloud::Cloud.locations[value]
            attrs[attr] = loc if loc.present?
          end
        end
        attrs
      end
      cloud = OO::Api::Cloud::Cloud.new(:ciName => Config.cloud, :ciAttributes => attributes)
      if cloud.save
        say cloud.to_pretty
      else
        say "#{'Failed:'.yellow}\n   #{cloud.errors.join("\n   ")}"
      end
    end

    def update(*args)
      cloud = OO::Api::Cloud::Cloud.find(Config.cloud)
      args.each do |a|
        attr, value = a.split('=', 2)
        cloud.ciAttributes[attr] = value if attr && value
      end
      if cloud.save
        say cloud.to_pretty
      else
        say "#{'Failed:'.yellow}\n   #{cloud.errors.join("\n   ")}"
      end
    end

    def delete(*args)
      cloud = OO::Api::Cloud::Cloud.find(Config.cloud)
      say "#{'Failed:'.yellow}\n   #{cloud.errors.join("\n   ")}" unless cloud.destroy
    end

    def locations(*args)
      say OO::Api::Cloud::Cloud.locations.to_pretty
    end

    def service(*args)
      OO::Cli::Command::Cloud::Service.new.process(*args)
    end

    def help(*args)
      subcommand = args.shift
      if subcommand == 'service'
        OO::Cli::Command::Cloud::Service.new.help(*args)
      else
        display <<-COMMAND_HELP
Usage:
   oneops cloud

   Management of clouds.

#{options_help}

Available actions:

   cloud list
   cloud show      -c <CLOUD>
   cloud create    -c <CLOUD> <attribute>=<VALUE> [<attribute>=<VALUE> ...]
   cloud update    -c <CLOUD> <attribute>=<VALUE> [<attribute>=<VALUE> ...]
   cloud delete    -c <CLOUD>
   cloud locations


Available attributes:

   description    Cloud description.
   location       Cloud location.
   auth           Authorization key (required only for clouds with custom locations).

Available subcommands:

    cloud service  -c <CLOUD> ...

COMMAND_HELP
      end
    end
  end
end
