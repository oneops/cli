module OO::Cli
  class Command::Transition::Environment < Command::Base
    def option_parser
      OptionParser.new do |opts|
        opts.on('-e', '--environment ENVIRONMENT', 'Environment name') { |e| Config.set_in_place(:environment, e)}
        opts.on(      '--clouds \'{<cloud_name_or_id>:{"priority":<1|2>,"dpmt_order":<order>,"pct_scale":<percent>},...}\'', 'Clouds.') { |cc| @clouds = cc}
        opts.on(      '--availability [PLATFORM=single|default,[...]]', Array, 'Platform availability') { |pa| @platform_availability = pa.presence || []}
        opts.on('-i', '--interval SECONDS', 'Poll interval in seconds for status of deployment plan generation on commit (default - 5 seconds, specify 0 to return immediately)') { |i| @poll_interval = i.to_i}
      end
    end

    def validate(action, *args)
      unless action == :default || action == :list || Config.environment.present?
        say 'Please specify environment!'.red
        return false
      end

      if action == :create
        if @clouds.blank?
          say 'Please specify clouds!'.red
          return false
        end
      end

      return true
    end

    def default(*args)
      Config.environment.present? ? show(*args) : list(*args)
    end

    def list(*args)
      envs = OO::Api::Transition::Environment.all(Config.assembly)
      say envs.to_pretty
    end

    def show(*args)
      env = OO::Api::Transition::Environment.find(Config.assembly, Config.environment)
      say env.to_pretty
    end

    def create(*args)
      attributes = args.inject({}) do |attrs, a|
        attr, value = a.split('=', 2)
        attrs[attr] = value if attr && value
        attrs
      end
      env = OO::Api::Transition::Environment.new(Config.assembly, {:ciName => Config.environment, :ciAttributes => attributes})

      clouds = parse_clouds(@clouds)
      return unless clouds
      env.clouds = clouds

      if @platform_availability
        env.platform_availability = @platform_availability.inject({}) do |a, availability|
          platform, availability = availability.split('=', 2)
          a[platform] = availability
          a
        end
      else
        env.platform_availability = OO::Api::Design::Platform.all(Config.assembly).inject({}) do |a, p|
          a[p.ciName] = 'default'
          a
        end
      end

      if env.save
        say env.to_pretty
      else
        say "#{'Failed:'.yellow}\n   #{env.errors.join("\n   ")}"
      end
    end

    def update(*args)
      env = OO::Api::Transition::Environment.find(Config.assembly, Config.environment)
      args.each do |a|
        attr, value = a.split('=', 2)
        env.ciAttributes[attr] = value if attr && value
      end

      clouds = parse_clouds(@clouds)
      env.clouds = clouds if clouds.present?

      if env.save
        say env.to_pretty
      else
        say "#{'Failed:'.yellow}\n   #{env.errors.join("\n   ")}"
      end
    end

    def enable(*args)
      env = OO::Api::Transition::Environment.find(Config.assembly, Config.environment)
      plats = OO::Api::Transition::Platform.all(Config.assembly, Config.environment)
      say "#{'Failed:'.yellow}\n   #{env.errors.join("\n   ")}" unless env.enable(plats.map(&:ciId))
    end

    def disable(*args)
      env = OO::Api::Transition::Environment.find(Config.assembly, Config.environment)
      plats = OO::Api::Transition::Platform.all(Config.assembly, Config.environment)
      say "#{'Failed:'.yellow}\n   #{env.errors.join("\n   ")}" unless env.disable(plats.map(&:ciId))
    end

    def delete(*args)
      env = OO::Api::Transition::Environment.find(Config.assembly, Config.environment)
      say "#{'Failed:'.yellow}\n   #{env.errors.join("\n   ")}" unless env.destroy
    end

    def commit(*args)
      release = OO::Api::Transition::Release.latest(Config.assembly, Config.environment)
      unless release && release.releaseState == 'open'
        say 'Nothing to commit!'.yellow
        return
      end

      env = OO::Api::Transition::Environment.find(Config.assembly, Config.environment)
      if env.commit(@desc)
        release = OO::Api::Transition::Release.latest(Config.assembly, Config.environment)
        say 'Committed release.'
        release_status(release)
        return if @poll_interval == 0

        interval = (@poll_interval || 5).to_i
        generating = true
        say 'Waiting for deployment plan generation.'
        while generating do
          env = OO::Api::Transition::Environment.find(Config.assembly, Config.environment)
          blurt Time.now.strftime('%H:%M:%S')
          blurt ' ... '
          say "generating...\n"
          if env.ciState == 'locked'
            sleep interval
          else
            generating = false
          end
        end
        comments = env.comments
        say comments.start_with?('ERROR:') ? comments.red : comments
      else
        say "#{'Failed:'.yellow}\n   #{env.errors.join("\n   ")}"
      end
    end

    def discard(*args)
      release = OO::Api::Transition::Release.latest(Config.assembly, Config.environment)
      if release && release.releaseState == 'open'
        env = OO::Api::Transition::Environment.find(Config.assembly, Config.environment)
        if env.discard
          release = OO::Api::Transition::Release.latest(Config.assembly, Config.environment)
          say 'Discarded release.'
          release_status(release)
        else
          say "#{'Failed:'.yellow}\n   #{env.errors.join("\n   ")}"
        end
      else
        release_status(release)
        say 'Nothing to discard!'.yellow
      end
    end

    def open(*args)
      env = OO::Api::Transition::Environment.find(Config.assembly, Config.environment)
      open_ci(env.ciId)
    end

    def help(*args)
      display <<-COMMAND_HELP
Usage:
   oneops transition environment

   Management of environments in transition.

#{options_help}

Available actions:

    transition environment list    -a <ASSEMBLY>
    transition environment show    -a <ASSEMBLY> -e <ENVIRONMENT>
    transition environment open    -a <ASSEMBLY> -e <ENVIRONMENT>
    transition environment create  -a <ASSEMBLY> -e <ENVIRONMENT> --clouds CLOUDS_JSON [<attribute>=<VALUE> [<attribute>=<VALUE> ...]] [--availability <PLATFORM>=single|redundant[,...]]
    transition environment update  -a <ASSEMBLY> -e <ENVIRONMENT> [<attribute>=<VALUE> [<attribute>=<VALUE> ...]]
    transition environment enable  -a <ASSEMBLY> -e <ENVIRONMENT>
    transition environment disable -a <ASSEMBLY> -e <ENVIRONMENT>
    transition environment delete  -a <ASSEMBLY> -e <ENVIRONMENT>
    transition environment commit  -a <ASSEMBLY> -e <ENVIRONMENT> [--comment <COMMENT>]
    transition environment discard -a <ASSEMBLY> -e <ENVIRONMENT>

Example:
   transition environment update -a ASSEMBLY1 -e QA debug=true --clouds '{"qa-cdc1":{"priority":1,"dpmt_order":3},"prod-dfw3":{"pct_scale":75,"priority":1},"prod-dfw4":{"priority":2}}' --availability tomcat_plat=default

COMMAND_HELP
    end

    private

    def parse_clouds(clouds)
      clouds = nil
      begin
        clouds = JSON.parse(@clouds)
      rescue Exception => e
        say 'Invalid clouds specification'.red
        say e
        return nil
      end
      clouds.each_pair do |cloud, cloud_info|
        priority = cloud_info['priority'].to_i
        unless priority == 1 || priority == 2
          say 'Invalid clouds specification - make sure to specify priority of 1 or 2 for each cloud!'.red
          return nil
        end
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
  end
end
