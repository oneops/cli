module OO::Cli
  class Command::Account::Profile < Command::Base
    def option_parser
      OptionParser.new do |opts|
        opts.on('-o', '--organization ORGANIZATION', 'Organization name') { |o| Config.set_in_place(:organization, o)}
      end
    end

    def validate(action, *args)
      if action ==:change_organization && !Config.organization.present?
        say 'Please specify organization!'.red
        return false
      end

      return true
    end

    def default(*args)
      show(*args)
    end

    def show(*args)
      profile = OO::Api::Account::Profile.find
      say profile.to_pretty
    end

    def change_organization(*args)
      orgs = OO::Api::Account::Organization.all
      org = orgs.find {|o| o.name == Config.organization}
      if org
        profile = OO::Api::Account::Profile.find
        if profile.change_organization(org.data[:id])
          say 'Successfully changed organization.'.magenta
          OO::Cli::Command::Account::Organization.new.list
        else
          say "#{'Failed:'.yellow}\n   #{org.errors.join("\n   ")}"
        end
      else
        say "#{'Failed:'.yellow}\n   Organization '#{Config.organization}' not found."
      end
    end

    def help(*args)
      display <<-COMMAND_HELP
Usage:
   oneops|oo account/profile

   Management of user profile.

#{options_help}

Available actions:

   account/profile:show
   account/profile:change_organization

COMMAND_HELP
    end
    
  end
end
