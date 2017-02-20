module OO::Cli
  class Command::Go < Command::Base
    def help(*args)
      display <<-COMMAND_HELP
Usage:
   oo go design-env-deploy.yaml
  Batch mode to run CLI commands alllowing for YAML driven end-to-end automation: from assembly creation to deployment.
Available actions:

   oo go <YAML FILE>

Here is an example of 'go' commandn YAML file configuraion:

---
aspect: config set
scope: global
attributes:
  site: http://localhost:3000
  organization: O1
---
aspect: assembly create
assembly: G1
attributes:
  owner: blah@gmail.com
---
aspect: design load
file: design.yaml
---
aspect: design/platform update
platform: cust
attributes:
  description: interesting
---
#{'# Concise way of specifying command.'.blue}
aspect: design/component update
component: compute
attributes:
  size_: L #{"# This attribute is 'locked' (user '_' after attribute name).".blue}
  require_public_ip: true
---
#{'# Explicit specifying of command.'.blue}
aspect: design
action: commit
comment: auto-commit via 'oo go'
---
aspect: transition/environment create
environment: Env1
clouds: '{"Main":{"priority":1,"dpmt_order":1}}'
attributes:
  availability: single
---
aspect: transition/environment commit
comment: auto-commit of env via 'oo go'
attributes:
  availability: single
---
aspect: transition/environment open



COMMAND_HELP
    end

    def option_parser
      OptionParser.new do |opts|
        opts.on('-u', '--stop_on_failure', 'Stop and exit on "soft" failures (i.e. 422). By default: stop on "hard" failures only (i.e. 404, 500).') { |p| @stop_on_soft_failure = true}
        opts.on('-c', '--component COMPONENT', 'Component name') { |c| Config.set_in_place(:component, c)}
        opts.on('-d', '--sibling_depends C1[,C2[,...]]', Array, 'Dependence to other sibling components (i.e. of the same type)') { |sd|  b@sibling_depends = sd}
      end
    end

    def default(*args)
      go(*args)
    end

    def print_end
      puts "### end ###\n\n\n".blue
    end

    def go(*args)

      if args.size == 0
        help(*args)
        exit 1
      end

      cmd_file = args.shift
      unless File.exists?(cmd_file)
        say "Could not find file: #{cmd_file.magenta}".red
        return false
      end

      switches = {'assembly'    => '-a',
                  'environment' => '-e',
                  'platform'    => '-p',
                  'component'   => '-c',
                  'type'        => '-t',
                  'file'        => '--file',
                  'comment'     => '--comment',
                  'interval'    => '-i',
                  'synchronous' => '-w',
                  'clouds'      => '--clouds'}

      say "Using file: #{cmd_file.cyan}"

      part = 0

      YAML.load_stream(File.read(cmd_file)) do |cmd|
        part += 1
        say "### start #{Time.now} part: #{part} ###".blue
        say "#{JSON.pretty_generate(cmd)}".green
        if cmd.has_key?('sleep')
          puts "sleeping #{cmd['sleep']}s..."
          sleep cmd['sleep']
          print_end
          next
        end
        unless cmd.has_key?('aspect')
          say 'missing aspect attr in the command'.red
          exit 1
        end

        aspect = cmd['aspect'].split(/\/|:|\s/)
        starting_command = aspect.first
        starting_cmd_class = OO::Cli::Command.const_get(starting_command.capitalize)

        args = aspect[1..-1]
        if args.blank?
          args.push cmd['kind'] if cmd.has_key?('kind')
          args.push cmd['action'] if cmd.has_key?('action')
        end

        args.push '-g' if cmd.has_key?('scope') && cmd['scope'] == 'global'
        args.push '-l' if cmd.has_key?('scope') && cmd['scope'] == 'local'

        switches.each_pair do |key, switch|
          if cmd.has_key?(key)
            args << switch
            args << cmd[key]
          end
        end

        if cmd.has_key?('attributes')
          cmd['attributes'].each_pair do |k,v|
            args.push "#{k}=#{v}"
          end
        end

        start = Time.now.to_f

        # use forked cli + jq for filtering ie get ip or other attribute value list
        if cmd.has_key?('jq')
          cmd_line = "oo #{starting_command} #{args.join(' ')} -f json | jq '#{cmd['jq']}'"
          puts cmd_line
          puts `#{cmd_line}`
        else
          command = starting_cmd_class.new
          begin
            command.send(:process, *args)
          rescue OO::Api::NotFoundException
            say('Not Found'.red)
          end
          break if command.failed? && @stop_on_soft_failure
        end

        duration = (Time.now.to_f - start).round(3)
        puts "took: #{duration}ms"
        print_end
      end
    end
  end
end
