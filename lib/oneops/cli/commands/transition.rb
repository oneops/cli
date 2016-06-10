module OO::Cli
  class Command::Transition < Command::Base
    def option_parser
      OptionParser.new do |opts|
        opts.on('-a', '--assembly ASSEMBLY', 'Assembly name') { |a| Config.set_in_place(:assembly, a)}
        opts.on('-e', '--environment ENVIRONMENT', 'Environment name') { |e| Config.set_in_place(:environment, e)}
        opts.on(      '--comment [TEXT]', 'Commit comment') { |a| @desc = a}
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
      OO::Api::Transition::Platform.all(Config.assembly, Config.environment).sort_by(&:ciName).each do |p|
        description = p.ciAttributes.description
        say "  #{p.ciName.rpad(20).cyan} #{p.ciAttributes.pack.rpad(15).magenta} #{(p.ciAttributes.is_active == 'true' ? 'active' : 'inactive').rpad(8).yellow} #{description.trunc(30) if description.present?}"
      end

      catalog  = OO::Api::Design::Release.latest(Config.assembly)
      manifest = OO::Api::Transition::Release.latest(Config.assembly, Config.environment)
      pull_status(catalog, manifest)
      release_status(manifest)
      deployment_status
    end

    def pull(*args)
      env = OO::Api::Transition::Environment.find(Config.assembly, Config.environment)
      env.platform_availability = args.inject({}) do |a, e|
        platform, availability = e.split('=', 2)
        a[platform] = availability
        a
      end
      if env.pull_design
        catalog  = OO::Api::Design::Release.latest(Config.assembly)
        manifest = OO::Api::Transition::Release.latest(Config.assembly, Config.environment)
        pull_status(catalog, manifest)
      else
        say "#{'Failed:'.yellow}\n   #{env.errors.join("\n   ")}"
      end
    end

    def commit(*args)
      release = OO::Api::Transition::Release.latest(Config.assembly, Config.environment)
      env = OO::Api::Transition::Environment.find(Config.assembly, Config.environment)
      if env.commit(@desc)
        release = OO::Api::Transition::Release.latest(Config.assembly, Config.environment)
        release_status(release)
      else
        say "#{'Failed:'.yellow}\n   #{env.errors.join("\n   ")}"
      end
    end

    def discard(*args)
      release = OO::Api::Transition::Release.latest(Config.assembly, Config.environment)
      if release && release.releaseState == 'open'
        if release.discard
          release = OO::Api::Transition::Release.latest(Config.assembly, Config.environment)
          release_status(release)
        else
          say "#{'Failed:'.yellow}\n   #{release.errors.join("\n   ")}"
        end
      else
        say "Nothing to discard!".yellow
        release_status(release)
      end
    end

    def variable(*args)
       OO::Cli::Command::Transition::Variable.new.process(*args)
     end

     def environment(*args)
       OO::Cli::Command::Transition::Environment.new.process(*args)
     end

     def platform(*args)
       OO::Cli::Command::Transition::Platform.new.process(*args)
     end

     def component(*args)
       OO::Cli::Command::Transition::Component.new.process(*args)
     end

     def attachment(*args)
       OO::Cli::Command::Transition::Attachment.new.process(*args)
     end

    def deployment(*args)
      OO::Cli::Command::Transition::Deployment.new.process(*args)
    end

    def help(*args)
      subcommand = args.shift
      if subcommand == 'environment'
        OO::Cli::Command::Transition::Environment.new.help(*args)
      elsif subcommand == 'platform'
        OO::Cli::Command::Transition::Platform.new.help(*args)
      elsif subcommand == 'component'
        OO::Cli::Command::Transition::Component.new.help(*args)
      elsif subcommand == 'variable'
        OO::Cli::Command::Transition::Variable.new.help(*args)
      elsif subcommand == 'attachment'
        OO::Cli::Command::Transition::Attachment.new.help(*args)
      elsif subcommand == 'deployment'
        OO::Cli::Command::Transition::Deployment.new.help(*args)
      else
        display <<-COMMAND_HELP
Usage:
   oneops transition

   Transition management.

#{options_help}

Available actions:

    transition show    -a <ASSEMBLY> -e <ENVIRONMENT>
    transition pull    -a <ASSEMBLY> -e <ENVIRONMENT> [<PLATFORM>=single|redundant [...]]
    transition commit  -a <ASSEMBLY> -e <ENVIRONMENT> [--comment <COMMENT>]
    transition discard -a <ASSEMBLY> -e <ENVIRONMENT>


Available subcommands:

    transition environment -a <ASSEMBLY> ...
    transition variable    -a <ASSEMBLY> -e <ENVIRONMENT> ...
    transition platform    -a <ASSEMBLY> -e <ENVIRONMENT> ...
    transition component   -a <ASSEMBLY> -e <ENVIRONMENT> ...
    transition deployment  -a <ASSEMBLY> -e <ENVIRONMENT> ...

COMMAND_HELP
      end
    end


    private

    def pull_status(catalog, manifest)
      if manifest && manifest.respond_to?(:parentReleaseId) && manifest.parentReleaseId == catalog.releaseId
        say "\nEnvironment has latest design release #{catalog.releaseId.to_s.cyan}"
      else
        say "\nNew design release #{catalog.releaseId.to_s.cyan} committed #{Time.at(catalog.updated / 1000)}."
        say "  Last design pulled in this environment was #{manifest.parentReleaseId.to_s.cyan}." if manifest && manifest.respond_to?(:parentReleaseId)
      end
    end

    def release_status(release)
      if release
        say "\nRelease: #{release.releaseId.to_s.cyan} (#{release.releaseState.yellow}) created by #{release.createdBy.magenta} #{Time.at(release.created / 1000)}."
        if release.releaseState == 'closed'
          say "  Committed by #{release.commitedBy.magenta} #{Time.at(release.updated / 1000)}."
          blurt '  Description: '
          say "#{release.description}".cyan
        end
      end

    end

    def deployment_status
      begin
        deployment = OO::Api::Transition::Deployment.latest(Config.assembly, Config.environment)
        say "\nDeployment: #{deployment.deploymentId.to_s.cyan} (#{deployment.deploymentState.yellow})."
      rescue OO::Api::NotFoundException
        begin
          bom = OO::Api::Transition::Release.bom(Config.assembly, Config.environment)
        rescue OO::Api::NotFoundException
          bom = nil
        end
        say "\nDeployment: #{'pending'.yellow}." if bom
      end
    end
  end
end
