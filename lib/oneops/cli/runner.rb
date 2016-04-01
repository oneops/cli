require 'optparse'

class OO::Cli::Runner
  class UnknownCommand < RuntimeError
  end

  attr_reader :args, :options, :option_parser

  OPTION_PARSER = OptionParser.new do |opts|
    opts.banner = "\nAvailable options:\n\n"

    opts.on('-d', '--debug', 'Output debug info') { OO::Cli::Config.debug = true }
    opts.on('-f', '--format FORMAT', [:console, :yaml, :json, :xml, :pretty_json], 'Output format: console, yaml, json or xml (default: console)') { |f| OO::Cli::Config.set_in_place(:format, f) }
    opts.on('--file FILE', 'Read attributes from  yaml file.') { |f| @attributes_file = f }
    opts.on('-k', '--insecure', 'Skip SSL validation.') { OO::Cli::Config.set_in_place(:insecure, 'true') }
    opts.on('--no-color', 'Do not colorize output') { OO::Cli::Config.colorize = false }
    opts.on('-o', '--organization ORGANIZATION', 'OneOps organization') { |organization| OO::Cli::Config.set_in_place(:organization, organization)}
    opts.on('-q', '--quiet', 'No output') { OO::Cli::Config.output = nil }
    opts.on('-R', '--raw-output', 'Output raw json from API response') { OO::Cli::Config.set_in_place(:raw_output, true) }
    opts.on('-s', '--site SITE', 'OneOps host site URL (default: https://api.oneops.com)') { |site| OO::Cli::Config.set_in_place(:site, site)}
    opts.on('--timing', 'Show command time duration stat.') { OO::Cli::Config.set_in_place(:timing, 'true') }
  end

  def self.run(args)
    new(args).run
  end

  def initialize(args = [])
    @args = args
  end

  def run
    start_time  = Time.now
    ok = false
    begin
      trap('TERM') { print "\nTerminated\n"; exit(false) }

      parse_options!

      if @attributes_file.present?
        OO::Cli::Config.set_in_place(:attributes_file, @attributes_file)
        YAML.load(File.open(@attributes_file)).each_pair { |k, v| @args << "#{k}=#{v}" }
      end

      # By default (no arguments) run general help command.
      if @args.blank?
        @args << 'help'
      end
      help = @args.delete('help')
      args = @args.blank? ? [] : @args.shift.split(/\/|:/) + @args
      command = help || args.shift

      begin
        case command
        when 'd'
          command = 'design'
        when 't'
          command = 'transition'
        when 'o'
          command = 'operations'
        end
        cmd = OO::Cli::Command.const_get(command.capitalize)
      rescue NameError => e
        raise UnknownCommand.new("Unknown command [#{command}]")
      end
      cmd.new.send(:process, *args)
      ok = true
    rescue UnknownCommand, OptionParser::InvalidOption, OptionParser::MissingArgument, OptionParser::InvalidArgument => e
      say(e.message.red)
    rescue Errno::ECONNREFUSED => e
      say("Cannot connect - #{e.message}".red)
    rescue OO::Api::UnauthroizedException
      say('Not Authorized'.red)
    rescue OO::Api::NotFoundException
      say('Not Found'.red)
      ok = true
    rescue Interrupt
      ok = true
    rescue SystemExit => e
      ok = e.success?
    rescue Exception => e
      puts e.class
      puts e.message
      puts e.backtrace
    ensure
      if OO::Cli::Config.debug || OO::Cli::Config.timing == 'true'
        say ok ? "#{'DONE'.green} (#{"#{((Time.now - start_time) * 100).round / 100.0}ms".cyan}) " : 'FAILED'.red
      end
    end
    exit(ok)
  end


  private

  def parse_options!

    # This obscured technique is to work around InvalidOption exception of OptionParser.  This will allow us to pluck relevant (see above)
    # options no matter where they located in the whole command line string.
    leftover_args = []
    while true
      begin
        leftover_args = OPTION_PARSER.permute!(@args.dup)
        break
      rescue OptionParser::InvalidOption => e
        @args = @args.map do |arg|
          if arg.start_with?(e.args[0])
            arg.dup.insert(0, '~*~*~')
          else
            arg.dup
          end
        end
      end
    end

    leftover_args.collect! {|arg| arg.gsub('~*~*~', '')}
    @args = leftover_args
  end
end
