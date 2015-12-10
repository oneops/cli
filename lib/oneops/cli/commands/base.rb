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
          # exception because we want give a chance to subcommands to process the options so that they plucked by
          # relevant command.
          leftover_args = []
          while true
            begin
              leftover_args = @option_parser ? @option_parser.permute!(args.dup) : args
              break
            rescue OptionParser::InvalidOption => e
              args = args.map do |arg|
                if arg.start_with?(e.args[0])
                  arg.dup.insert(0, '~*~*~')
                else
                  arg.dup
                end
              end
            end
          end

          leftover_args.collect! {|arg| arg.gsub('~*~*~', '')}
          action = leftover_args.detect {|a| respond_to?(a)}
          if action.present?
            action = leftover_args.delete(action).to_sym
          elsif leftover_args.blank?
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

      def options_help
        @option_parser ||= option_parser
        @option_parser.banner = "\nAvailable options:\n\n"
        @option_parser
      end
    end
  end
end

