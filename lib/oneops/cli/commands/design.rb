module OO::Cli
  class Command::Design < Command::Base
    def option_parser
      OptionParser.new do |opts|
        opts.on('-a', '--assembly ASSEMBLY', 'Assembly name') { |a| Config.set_in_place(:assembly, a)}
        opts.on('-C TEXT', 'Commit comment') { |a| @desc = a}
      end
    end

    def validate(action, *args)
      unless Config.assembly
        say 'Please specify assembly!'.red
        return false
      end

      return true
    end

    def default(*args)
      show(*args)
    end

    def show(*args)
      say "\nPlatforms:"
      say "  #{'Name'.rpad(20)} #{'Pack'.rpad(15)} #{'Description'.rpad(40)}"
      say "  #{''.rpad(20, '-')} #{''.lpad(15, '-')} #{''.rpad(40, '-')}"
      OO::Api::Design::Platform.all(Config.assembly).sort_by(&:ciName).each do |p|
        description = p.ciAttributes.description
        say "  #{p.ciName.rpad(20).cyan} #{p.ciAttributes.pack.rpad(15).magenta} #{description.trunc(40) if description.present?}"
      end

      release = OO::Api::Design::Release.latest(Config.assembly)
      if release
        say "\nCurrent Release: #{release.releaseId.to_s.cyan} (#{release.releaseState.yellow}) created by #{release.createdBy.magenta} on #{Time.at(release.created / 1000)}."
        if release.releaseState == 'closed'
          say "  Committed by #{release.commitedBy.magenta} #{Time.at(release.updated / 1000)}."
          blurt '  Description:'
          say "#{release.description}".cyan
        end
      end
    end

    def commit(*args)
      release = OO::Api::Design::Release.latest(Config.assembly)
      if release && release.releaseState == 'open'
        release.commit(@desc)
      else
        say 'Nothing to commit.'.yellow
      end
    end

    def discard(*args)
      release = OO::Api::Design::Release.latest(Config.assembly)
      if release && release.releaseState == 'open'
        release.discard
      else
        say 'Nothing to discard.'.yellow
      end
    end

    def packs(*args)
      say OO::Api::Pack.all.to_pretty
    end

    def variable(*args)
      OO::Cli::Command::Design::Variable.new.process(*args)
    end

    def platform(*args)
      OO::Cli::Command::Design::Platform.new.process(*args)
    end

    def component(*args)
      OO::Cli::Command::Design::Component.new.process(*args)
    end

    def attachment(*args)
      OO::Cli::Command::Design::Attachment.new.process(*args)
    end

    def help(*args)
      subcommand = args.shift
      if subcommand == 'platform'
        OO::Cli::Command::Design::Platform.new.help(*args)
      elsif subcommand == 'component'
        OO::Cli::Command::Design::Component.new.help(*args)
      elsif subcommand == 'variable'
        OO::Cli::Command::Design::Variable.new.help(*args)
      elsif subcommand == 'attachment'
        OO::Cli::Command::Design::Attachment.new.help(*args)
      else
        display <<-COMMAND_HELP
Usage:
   oneops design

   Assembly design management.

#{options_help}

Available actions:

    design show    -a <ASSEMBLY>
    design commit  -a <ASSEMBLY> [--comment <COMMENT>]
    design discard -a <ASSEMBLY>
    design packs


Available subcommands:

    design platform   -a <ASSEMBLY> ...
    design variable   -a <ASSEMBLY> ...
    design component  -a <ASSEMBLY> ...
    design attachment -a <ASSEMBLY> ...

COMMAND_HELP
      end
    end
  end
end
