module OO::Cli
  class Command::Operations < Command::Base
    def option_parser
      OptionParser.new do |opts|
        opts.on('-a', '--assembly ASSEMBLY', 'Assembly name') { |a| Config.set_in_place(:assembly, a)}
        opts.on('-e', '--environment ENVIRONMENT', 'Environment name') { |e| Config.set_in_place(:environment, e)}
      end
    end

    def validate(action, *args)
      unless Config.assembly
        say 'Please specify assembly!'.red
        return false
      end

      unless Config.environment || action == :default || action == :environment
        say 'Please specify environment!'.red
        return false
      end

      return true
    end

    def default(*args)
      Config.environment.present? ? show(*args) : environment('list')
    end

    def show(*args)
      say "\nPlatforms:"
      say "  #{'Name'.rpad(20)} #{'Pack'.rpad(15)} #{'Status'.rpad(8)} #{'Description'.rpad(30)}"
      say "  #{''.rpad(20, '-')} #{''.lpad(15, '-')} #{''.rpad(8, '-')} #{''.rpad(30, '-')}"
      OO::Api::Operations::Platform.all(Config.assembly, Config.environment).sort_by(&:ciName).each do |p|
        description = p.ciAttributes.description
        say "  #{p.ciName.rpad(20).cyan} #{p.ciAttributes.pack.rpad(15).magenta} #{(p.ciAttributes.is_active == 'true' ? 'active' : 'inactive').rpad(8).yellow} #{description.trunc(30) if description.present?}"
      end
    end

     def environment(*args)
       OO::Cli::Command::Operations::Environment.new.process(*args)
     end

     def platform(*args)
       OO::Cli::Command::Operations::Platform.new.process(*args)
     end

     def component(*args)
       OO::Cli::Command::Operations::Component.new.process(*args)
     end

     def instance(*args)
       OO::Cli::Command::Operations::Instance.new.process(*args)
     end
     
    def help(*args)
      subcommand = args.shift
      if subcommand == 'environment'
        OO::Cli::Command::Operations::Environment.new.help(*args)
      elsif subcommand == 'platform'
        OO::Cli::Command::Operations::Platform.new.help(*args)
      elsif subcommand == 'component'
        OO::Cli::Command::Operations::Component.new.help(*args)
      elsif subcommand == 'instance'
        OO::Cli::Command::Operations::Instance.new.help(*args)
      else
        display <<-COMMAND_HELP
Usage:
   oneops operations

   Operations management.

#{options_help}

Available actions:

    operations show -a <ASSEMBLY> -e <ENVIRONMENT>


Available subcommands:

    operations environment -a <ASSEMBLY> ...
    operations platform    -a <ASSEMBLY> -e <ENVIRONMENT> ...
    operations component   -a <ASSEMBLY> -e <ENVIRONMENT> -p <PLATFROM> ...
    operations instance    -a <ASSEMBLY> -e <ENVIRONMENT> -p <PLATFORM> -c <COMPONENT> ...

COMMAND_HELP
      end
    end

  end
end
