module OO::Cli
  class Command::Go < Command::Base
    
    #def process(*args)
    #  go(*args)
    #end

    require 'yaml'
        
    def help(*args)
      display <<-COMMAND_HELP
Usage:
   oo go design-env-deploy.yaml

Available actions:

   oo go <YAML FILE>

COMMAND_HELP
    end
    
    def doit(*args)
      go(*args)
    end
    
    def print_end
      puts "### end ###\n\n\n".blue 
    end
    
    def go(*args)
      
      cmd_file = args.shift
      unless File.exists?(cmd_file)
        say "Could not find file: #{cmd_file.magenta}".red
        return false
      end

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
          say "missing aspect attr in the command".red
          exit 1
        end
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

        start = Time.now.to_f
        
        # use forked cli + jq for filtering ie get ip or other attribute value list
        if cmd.has_key?('jq')
          cmd_line = "oo #{cmd['aspect']} #{args.join(' ')} -f json | jq '#{cmd['jq']}'"
          puts cmd_line
          puts `#{cmd_line}`
        else
          command.new.send(:process, *args)          
        end
        
        duration = (Time.now.to_f - start).round(3)
        puts "took: #{duration}ms"
        print_end
      end

    end

  end
end
