module OO::Cli
  class Command::Transition::Deployment < Command::Base
    def option_parser
      OptionParser.new do |opts|
        opts.on('-i', '--interval SECONDS', 'Poll interval in seconds') { |i| @poll_interval = i}
        opts.on('-w', '--wait', 'Wait for status on active deployments') {@wait = true}
      end
    end

    def validate(action, *args)
      return true
    end

    def default(*args)
      show(*args)
    end

    def show(*args)
      deployment = find_deployment
      return unless deployment

      say "\nDeployment: #{deployment.deploymentId.to_s.cyan} (#{deployment.deploymentState.yellow}) created by #{deployment.createdBy.magenta} #{Time.at(deployment.created / 1000)}."
      poll_status if (@wait && deployment.deploymentState == 'active')
    end

    def create(*args)
      begin
        bom = OO::Api::Transition::Release.bom(Config.assembly, Config.environment)
      rescue OO::Api::NotFoundException
        bom = nil
        # See if is possible to "force deploy" by recreating bom on the latest closed release.
        release = OO::Api::Transition::Release.latest(Config.assembly, Config.environment)
        if release && release.releaseState == 'closed'
          env = OO::Api::Transition::Environment.find(Config.assembly, Config.environment)
          if env.commit
            bom = OO::Api::Transition::Release.bom(Config.assembly, Config.environment)
          else
            say "#{'Failed:'.yellow}\n   #{env.errors.join("\n   ")}"
          end
        end
      end

      unless bom && bom.releaseState == 'open'
        say "\nNo pending deployment (bom) found.".yellow
        return
      end

      deployment = OO::Api::Transition::Deployment.new(Config.assembly, Config.environment, {:releaseId => bom.releaseId, :nsPath => bom.nsPath})
      if deployment.create
        say "\nDeployment: #{deployment.deploymentId.to_s.cyan} (#{deployment.deploymentState.yellow})."
        poll_status if @wait
      else
        say "#{'Failed:'.yellow}\n   #{deployment.errors.join("\n   ")}"
      end
    end

    def cancel(*args)
      deployment = find_deployment
      return unless deployment

      if deployment.deploymentState == 'active' or deployment.deploymentState == 'failed' or deployment.deploymentState == 'paused'
        if deployment.cancel
          say "\nDeployment: #{deployment.deploymentId.to_s.cyan} (#{deployment.deploymentState.yellow})."
        else
          say "#{'Failed:'.yellow}\n   #{deployment.errors.join("\n   ")}"
        end
      else
        say "\nNo open deployment found.".yellow
      end
    end

    def retry(*args)
      deployment = find_deployment
      return unless deployment

      if deployment.deploymentState == 'failed'
        if deployment.retry
          say "\nDeployment: #{deployment.deploymentId.to_s.cyan} (#{deployment.deploymentState.yellow})."
          poll_status if @wait
        else
          say "#{'Failed:'.yellow}\n   #{deployment.errors.join("\n   ")}"
        end
      else
        say "\nNo failed deployment found.".yellow
      end
    end

    def pause(*args)
      deployment = find_deployment
      return unless deployment

      if deployment.deploymentState == 'active'
        if deployment.pause
          say "\nDeployment: #{deployment.deploymentId.to_s.cyan} (#{deployment.deploymentState.yellow})."
        else
          say "#{'Failed:'.yellow}\n   #{deployment.errors.join("\n   ")}"
        end
      else
        say "\nNo active deployment found.".yellow
      end
    end

    def resume(*args)
      deployment = find_deployment
      return unless deployment

      if deployment.deploymentState == 'active' or deployment.deploymentState == 'paused'
        if deployment.resume
          say "\nDeployment: #{deployment.deploymentId.to_s.cyan} (#{deployment.deploymentState.yellow})."
          poll_status if @wait
        else
          say "#{'Failed:'.yellow}\n   #{deployment.errors.join("\n   ")}"
        end
      else
        say "\nNo failed deployment found.".yellow
      end
    end

    def approve(*args)
      deployment = find_deployment
      return unless deployment

      if deployment.deploymentState == 'pending'
        if deployment.update('active')
          say "\nDeployment: #{deployment.deploymentId.to_s.cyan} (#{deployment.deploymentState.yellow})."
          poll_status if @wait
        else
          say "#{'Failed:'.yellow}\n   #{deployment.errors.join("\n   ")}"
        end
      else
        say "\nNo pending deployment found.".yellow
      end
    end

    def help(*args)
      display <<-COMMAND_HELP
Usage:
   oneops transition deployment

   Management of deployments in transition.

#{options_help}

Available actions:

    transition deployment show    -a <ASSEMBLY> -e <ENVIRONMENT> [-w] [-i INTERVAL]
    transition deployment create  -a <ASSEMBLY> -e <ENVIRONMENT> [-w] [-i INTERVAL]
    transition deployment cancel  -a <ASSEMBLY> -e <ENVIRONMENT>
    transition deployment retry   -a <ASSEMBLY> -e <ENVIRONMENT> [-w] [-i INTERVAL]
    transition deployment pause   -a <ASSEMBLY> -e <ENVIRONMENT>
    transition deployment resume  -a <ASSEMBLY> -e <ENVIRONMENT> [-w] [-i INTERVAL]
    transition deployment approve -a <ASSEMBLY> -e <ENVIRONMENT> [-w] [-i INTERVAL]

COMMAND_HELP
    end


    private

    def find_deployment
      begin
        return OO::Api::Transition::Deployment.latest(Config.assembly, Config.environment)
      rescue OO::Api::NotFoundException
        say "\nNo deployment found.".yellow
        return nil
      end
    end

    def poll_status
      interval = @poll_interval.to_i
      active = true
      if @wait
        say "Waiting for active deployment to complete"
        while active do
          deployment = OO::Api::Transition::Deployment.latest(Config.assembly, Config.environment)
          blurt Time.now
          blurt ' ... '
          if deployment.deploymentState == 'active'
            sleep interval
          else
            active = false
          end
          say "#{deployment.deploymentState.yellow}\n"
        end
      end
    end
  end
end
