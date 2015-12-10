module OO::Cli
  class Command::Catalog < Command::Base
    def option_parser
      OptionParser.new do |opts|
        opts.on('-c', '--catalog CATALOG', 'Catalog name')    { |a| Config.set_in_place(:catalog, a)}
        opts.on(      '--public',          'Public catalog')  { @source = 'public'}
        opts.on(      '--private',         'Private catalog') { @source = 'private'}
      end
    end

    def validate(action, *args)
      unless action == :default || action == :list || Config.catalog.present?
        say 'Please specify catalog!'.red
        return false
      end

      return true
    end

    def default(*args)
      Config.catalog ? show(*args) : list(*args)
    end

    def list(*args)
      catalogs = OO::Api::Catalog.all
      say catalogs.to_pretty
    end

    def show(*args)
      catalog = OO::Api::Catalog.find(Config.catalog, @source)
      say catalog.to_pretty
    end

    def delete(*args)
      catalog = OO::Api::Catalog.find(Config.catalog)
      say "#{'Failed:'.yellow}\n   #{catalog.errors.join("\n   ")}" unless catalog.destroy
    end

    def help(*args)
      display <<-COMMAND_HELP
Usage:
   oneops catalog

   Management of catalogs.

#{options_help}

Available actions:

    catalog list
    catalog show    -c <CATALOG> [--public | --private]
    catalog delete  -c <CATALOG>

COMMAND_HELP
    end
  end
end
