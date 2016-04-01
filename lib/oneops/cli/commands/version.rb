module OO::Cli::Command
  class Version < Base
    skip_configure_api

    def process(*args)
      say OO::VERSION.green
    end

    def help(*args)
      display <<-COMMAND_HELP
Usage:
    oneops version

    Display oneops CLI version number.
      COMMAND_HELP
    end
  end
end
