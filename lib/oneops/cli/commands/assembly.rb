module OO::Cli
  class Command::Assembly < Command::Base
    def option_parser
      OptionParser.new do |opts|
        opts.on('-a', '--assembly ASSEMBLY', 'Assembly name') { |a| Config.set_in_place(:assembly, a)}
        opts.on('-t', '--target NAME', 'Name of new assembly or catalog for "clone" and "save to catalog" actions.') { |d| @target = d}
        opts.on(      '--description TEXT', 'Description of new assembly or catalog for "clone" and "save to catalog" actions.') { |a| @desc = a}
      end
    end

    def validate(action, *args)
      unless action == :default || action == :list || Config.assembly.present?
        say 'Please specify assembly!'.red
        return false
      end

      if (action == :clone || action == :catalog) && @target.blank?
        say 'Please specify target!'.red
        return false
      end

      return true
    end

    def default(*args)
      Config.assembly ? show(*args) : list(*args)
    end

    def list(*args)
      assemblies = OO::Api::Assembly.all
      say assemblies.to_pretty
    end

    def show(*args)
      assembly = OO::Api::Assembly.find(Config.assembly)
      say assembly.to_pretty
    end

    def create(*args)
      attributes = args.inject({}) do |attrs, a|
        attr, value = a.split('=', 2)
        attrs[attr] = value if attr && value
        attrs
      end
      assembly = OO::Api::Assembly.new(:ciName => Config.assembly, :ciAttributes => attributes)
      if assembly.save
        say assembly.to_pretty
      else
        say "#{'Failed:'.yellow}\n   #{assembly.errors.join("\n   ")}"
      end
    end

    def update(*args)
      assembly = OO::Api::Assembly.find(Config.assembly)
      args.each do |a|
        attr, value = a.split('=', 2)
        assembly.ciAttributes[attr] = value if attr && value
      end
      if assembly.save
        say assembly.to_pretty
      else
        say "#{'Failed:'.yellow}\n   #{assembly.errors.join("\n   ")}"
      end
    end

    def delete(*args)
      assembly = OO::Api::Assembly.find(Config.assembly)
      say "#{'Failed:'.yellow}\n   #{assembly.errors.join("\n   ")}" unless assembly.destroy
    end

    def clone(*args)
      assembly = OO::Api::Assembly.find(Config.assembly)
      clone = assembly.clone(@target, @desc)
      say clone ? clone.to_pretty : "#{'Failed:'.yellow}\n   #{assembly.errors.join("\n   ")}"
    end

    def catalog(*args)
      assembly = OO::Api::Assembly.find(Config.assembly)
      catalog = assembly.catalog(@target, @desc)
      say catalog ? catalog.to_pretty : "#{'Failed:'.yellow}\n   #{assembly.errors.join("\n   ")}"
    end

    def help(*args)
      display <<-COMMAND_HELP
Usage:
   oneops assembly

   Management of assemblies.

#{options_help}

Available actions:

   assembly list
   assembly show    -a <ASSEMBLY>
   assembly create  -a <ASSEMBLY> <attribute>=<VALUE> [<attribute>=<VALUE> ...]
   assembly update  -a <ASSEMBLY> <attribute>=<VALUE> [<attribute>=<VALUE> ...]
   assembly delete  -a <ASSEMBLY>
   assembly clone   -a <ASSEMBLY> -t <TARGET>
   assembly catalog -a <ASSEMBLY> -t <TARGET>


Available attributes:

   description    Assembly description.

COMMAND_HELP
    end
  end
end
