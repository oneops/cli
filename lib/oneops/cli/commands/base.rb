require 'launchy'

module OO::Cli
  module Command
    class Base
      @@configure_api = true
      def self.skip_configure_api
        @@configure_api = false
      end

      def process(*args)
        if !@@configure_api || OO::Cli::Config.configure_api
          @option_parser = option_parser

          # This obscured hack is to work around InvalidOption exception of OptionParser.  We do not want a hard
          # exception because we want to give a chance to subcommands to process the options so that options are
          # plucked by relevant command.
          leftover_args = []
          hide_prefix = "~*~#{SecureRandom.random_number(36**6).to_s(36)}~*~"
          while true
            begin
              leftover_args = @option_parser ? @option_parser.permute!(args.dup) : args
              break
            rescue OptionParser::InvalidOption => e
              i = args.index(e.args[0])
              raise e if i.nil?
              args[i] = "#{hide_prefix}#{e.args[0]}"
            end
          end

          leftover_args.map! {|arg| arg.gsub(hide_prefix, '')}
          action = leftover_args.detect {|a| respond_to?(a)}
          if action.present?
            action = leftover_args.delete(action).to_sym
          elsif self.respond_to?(:default)
            action = :default
          else
            say "Invalid action for command <#{self.class.name.split('::').last.downcase}>".red
            return
          end

          return unless validate(action, *leftover_args)

          send(action, *leftover_args)
        end
      end

      def option_parser
        nil
      end

      def validate(action, *args)
        true
      end

      def default
        say 'No default action for this command!'.yellow
      end

      def help(*args)
        say 'No help available!'
      end

      def open(*args)
        url = open_url(*args)
        if url
          Launchy.open(url)
        else
          say "Invalid action for command <#{self.class.name.split('::').last.downcase}>".red
        end
      end


      protected

      def options_help
        @option_parser ||= option_parser
        @option_parser.banner = "\nAvailable options:\n\n"
        @option_parser
      end

      def open_url(*args)
        nil
      end

      def open_ci(ci_id)
        Launchy.open("#{OO::Api::Config.site}/r/ci/#{ci_id}")
      end
    end
  end
end

