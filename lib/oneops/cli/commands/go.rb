  module OO::Cli
  class Command::Go < Command::Base

    require 'yaml'
        
    def option_parser
      OptionParser.new do |opts|
        opts.on('-f', '--file FILE', 'yaml or json file with command(s)') { |f| OO::Cli::Config.set_in_place(:cmd_file, f) }
      end
    end

    def help(*args)
      display <<-COMMAND_HELP
Usage:
   oneops go doit design-env-deploy.yaml

   go doit: yaml multi-part/stream file based input

Available actions:

    go doit <YAML FILE>

COMMAND_HELP
    end
    
    def default(*args)
      go(*args)
    end
    
    def doit(*args)
      go(*args)      
    end

    def go(*args)
      
      cmd_file = args.shift
      unless File.exists?(cmd_file)
        say "Could not find file: #{cmd_file.magenta}".red
        return false
      end

      say "Using file: #{cmd_file.cyan}"

      YAML.load_stream(File.read(cmd_file)) do |cmd|
        puts "### start ###"
        puts "#{JSON.pretty_generate(cmd)}"
        command = OO::Cli::Command.const_get(cmd['aspect'].capitalize)
        
        args = []
        args.push cmd['kind'] if cmd.has_key?('kind')          
        args.push cmd['action']
          
        args.push '-g' if cmd.has_key?('scope') && cmd['scope'] == 'global'
        args.push '-l' if cmd.has_key?('scope') && cmd['scope'] == 'local'
          
        args += ["-a", "#{cmd['assembly']}"] if cmd.has_key?('assembly')
        args += ["-p", "#{cmd['platform']}"] if cmd.has_key?('platform')
        args += ["-c", "#{cmd['component']}"] if cmd.has_key?('component')
        args += ["-t", "#{cmd['type']}"] if cmd.has_key?('type')
        args += ["-e", "#{cmd['environment']}"] if cmd.has_key?('environment')
        args += ["-i", "#{cmd['interval']}"] if cmd.has_key?('interval')
        args += ["--comment", "#{cmd['comment']}"] if cmd.has_key?('comment')
        args += ["-w"] if cmd.has_key?('synchronous') && cmd['synchronous'] == true
        args += ["--clouds", "#{cmd['clouds']}"] if cmd.has_key?('clouds')
        if cmd.has_key?('attributes')
          cmd['attributes'].each_pair do |k,v|
            args.push "#{k}=#{v}"
          end
        end
        puts "args: #{args}" if Config.debug
        start = Time.now.to_f
        command.new.send(:process, *args)
        duration = (Time.now.to_f - start).round(3)
        puts "took: #{duration}ms"
        puts "### end ###\n\n\n"
      end

    end

  end
end
