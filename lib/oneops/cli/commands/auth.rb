module OO::Cli::Command
  class Auth < Base
    def process(*args)
      action = args[0]
      action = action.nil? ? :login : action.to_sym
      unless respond_to?(action)
        say "Invalid action for command <#{self.class.name.split('::').last.downcase}>".red
        return
      end

      send(action, *(args.shift))
    end

    def login(*args)
      unless OO::Cli::Credentials.read(site)
        begin
          say 'Enter your OneOps credentials.'

          blurt 'Username: '
          user = ask

          blurt 'Password (typing will be hidden): '
          password = ask!

          OO::Cli::Credentials.write(site, [user, password])
        rescue Exception => e
          OO::Cli::Credentials.delete(site)
          raise e
        end
      end

      # Test credentials.
      begin
        OO::Cli::Config.configure_api
        token = OO::Api::Account::Profile.authentication_token
        raise OO::Api::UnauthroizedException.new unless token
        say 'Logged In'.green
        OO::Cli::Credentials.write(site, [token, 'X'])
      rescue OO::Api::UnauthroizedException
        say 'Invalid credentials'.red
        OO::Cli::Credentials.delete(site)
      rescue Exception => e
        OO::Cli::Credentials.delete(site)
        raise e
      end
    end

    def logout(*args)
      OO::Cli::Credentials.delete(site)
      say 'Logged out'.green
    end

    def help(*args)
      display <<-COMMAND_HELP
Usage: oneops auth

    Authentication for OneOps CLI session.


Available actions:

    auth login
    auth logout

COMMAND_HELP
    end

    private


    def site
      @site ||= (OO::Cli::Config.site || 'https://my.oneops.com')
    end
  end
end
