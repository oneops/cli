module OO::Cli
  class Command::Organization < Command::Base
    def option_parser
      OptionParser.new do |opts|
        opts.on('-s', '--state STATE', 'Health state') { |s| @state = s}
      end
    end

    def default(*args)
      show(*args)
    end

    def show(*args)
      organization = OO::Api::Organization.find
      say organization.to_pretty
    end
    
    def health(*args)
      health = OO::Api::Organization.health
      say health.to_pretty
    end

    def help(*args)
      display <<-COMMAND_HELP
Usage:
   oneops organization
   
   Management of organization.
   
#{options_help}

Available actions:

   organization show
   organization health [-s <STATE>]


Available attributes:


COMMAND_HELP
    end
  end
end
