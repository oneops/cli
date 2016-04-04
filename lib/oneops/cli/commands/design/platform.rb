module OO::Cli
  class Command::Design::Platform < Command::Base
    def option_parser
      OptionParser.new do |opts|
        opts.on('-p', '--platform PLATFORM', 'Platform name') { |a| Config.set_in_place(:platform, a)}
        opts.on('-l', '--links P1[,P2[,...]]', Array, 'Links to other platforms') { |ll| @links_to = ll}
        opts.on('-t', '--target ASSEMBLY:PLATFORM', 'Colon serated assembly and platform name of a new clone platform.') { |d| @target = d}
      end
    end

    def help(*args)
      display <<-COMMAND_HELP
Usage:
   oneops design platform

   Management of platforms in design.

#{options_help}

Available actions:

    design platform list   -a <ASSEMBLY>
    design platform show   -a <ASSEMBLY> -p <PLATFORM>
    design platform open   -a <ASSEMBLY> -p <PLATFORM>
    design platform create -a <ASSEMBLY> -p <PLATFORM> [<attribute>=<VALUE> [<attribute>=<VALUE> ...]] [-l <P1>[,<P2>[,...]]]
    design platform update -a <ASSEMBLY> -p <PLATFORM> [<attribute>=<VALUE> [<attribute>=<VALUE> ...]] [-l <P1>[,<P2>[,...]]]
    design platform delete -a <ASSEMBLY> -p <PLATFORM>
    design platform clone  -a <ASSEMBLY> -p <PLATFORM> -t <TARGET>

Available attributes:

    source    Template source.
    pack      Template name.
    version   Template version.

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
      platforms = OO::Api::Design::Platform.all(Config.assembly)
      say platforms.to_pretty( :title => Config.assembly )
    end

    def open(*args)
      platform = OO::Api::Design::Platform.find(Config.assembly, Config.platform)
      open_ci(platform.ciId)
    end

    def show(*args)
      platform = OO::Api::Design::Platform.find(Config.assembly, Config.platform)
      say platform.to_pretty
    end

    def create(*args)
      attributes = args.inject({}) do |attrs, a|
        attr, value = a.split('=', 2)
        attrs[attr] = value if attr && value
        attrs
      end
      platform = OO::Api::Design::Platform.new(Config.assembly, {:ciName => Config.platform, :ciAttributes => attributes})
      platform.links_to = @links_to
      if platform.save
        say platform.to_pretty
      else
        say "#{'Failed:'.yellow}\n   #{platform.errors.join("\n   ")}"
      end

    end

    def update(*args)
      platform = OO::Api::Design::Platform.find(Config.assembly, Config.platform)
      args.each do |a|
        attr, value = a.split('=', 2)
        platform.ciAttributes[attr] = value if attr && value
      end
      platform.links_to = @links_to
      if platform.save
        say platform.to_pretty
      else
        say "#{'Failed:'.yellow}\n   #{platform.errors.join("\n   ")}"
      end
    end

    def delete(*args)
      platform = OO::Api::Design::Platform.find(Config.assembly, Config.platform)
      say "#{'Failed:'.yellow}\n   #{platform.errors.join("\n   ")}" unless platform.destroy
    end

    def clone(*args)
      platform = OO::Api::Design::Platform.find(Config.assembly, Config.platform)
      clone = platform.clone(*(@target.split(':')[0..1]))
      if clone
        say clone.to_pretty
      else
        say "#{'Failed:'.yellow}\n   #{platform.errors.join("\n   ")}"
      end
    end
  end
end
