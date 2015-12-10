module OO::Cli
  class Command::Account::Organization < Command::Base
    def option_parser
      OptionParser.new do |opts|
        opts.on('-o', '--organization ORGANIZATION', 'Organization name') { |o| Config.set_in_place(:organization, o)}
      end
    end

    def validate(action, *args)
      unless action ==:default || action == :list || Config.organization.present?
        say 'Please specify organization!'.red
        return false
      end

      return true
    end

    def default(*args)
      list(*args)
    end

    def list(*args)
      current = OO::Api::Account::Profile.find.data[:organization]
      orgs = OO::Api::Account::Organization.all
      say "\nOrganizations:"
      orgs.each do |o|
        if current && current.name == o.name
          say "   #{o.name.magenta}   <=== current"
        else
          say "   #{o.name}"
        end
      end
    end

    def create(*args)
      org = OO::Api::Account::Organization.new(:name => Config.organization)
      if org.create
        say org.to_pretty
      else
        say "#{'Failed:'.yellow}\n   #{org.errors.join("\n   ")}"
      end
    end

    def leave(*args)
      org = find_organization
      if org
        if org.leave
          say 'Successfully left organization.'.magenta
          list
        else
          say "#{'Failed:'.yellow}\n   #{org.errors.join("\n   ")}"
        end
      end
    end

    def delete(*args)
      org = find_organization
      if org
        if org.delete
          say 'Successfully deleted organization.'.magenta
          list
        else
          say "#{'Failed:'.yellow}\n   #{org.errors.join("\n   ")}"
        end
      end
    end

    def help(*args)
      display <<-COMMAND_HELP
Usage:
   oneops|oo account/profile

   Management of user organizations.

#{options_help}

Available actions:

   account/organization:list
   account/organization:create -o <ORGANIZATION>
   account/organization:leave  -o <ORGANIZATION>
   account/organization:delete  -o <ORGANIZATION>

COMMAND_HELP
    end

    private

    def find_organization
      orgs = OO::Api::Account::Organization.all
      org = orgs.find {|o| o.name == Config.organization}
      say "#{'Failed:'.yellow}\n   Organization '#{Config.organization}' not found." unless org
      return org
    end
  end
end
