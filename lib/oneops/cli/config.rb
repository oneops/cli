require 'rubygems'

class Hash
  def method_missing(method_name, *args)
    if method_name.to_s.end_with?('=')
      self[method_name.to_s[0...-1]] = args[0]
    elsif self.include?(method_name)
      self[method_name]
    else
      super
    end
  end
end

require "yaml"
module OO
  module Cli
    class Config
      GLOBAL_FILE_NAME = File.expand_path('~/.oneops')
      LOCAL_FILE_NAME  = File.expand_path('./.oneops')

      class << self
        attr_accessor :global, :local, :in_place
        attr_accessor :output, :colorize, :debug

        def set_in_place(name, value)
          @in_place[name.to_sym] = value
        end

        def set(name, value, global = false)
          if global
            @global[name.to_sym] = value
            save(true)
          else
            @local[name.to_sym] = value
            save(false)
          end
        end

        def clear(name, global = false)
          if global
            @global.delete(name.to_sym)
            save(true)
          else
            @local.delete(name.to_sym)
            save(false)
          end
        end

        def data
          @global.merge(@local)
        end

        def method_missing(method_name, *args)
          get_value(method_name)
        end

        def configure_api
          OO::Api::Config.debug = OO::Cli::Config.debug
          OO::Api::Config.timeout = OO::Cli::Config.timeout
          OO::Api::Config.verify_ssl = (OO::Cli::Config.insecure != 'true')
          OO::Api::Config.organization = OO::Cli::Config.organization

          site = OO::Cli::Config.site || 'http://localhost:3000'
          OO::Api::Config.site = site

          credentials = OO::Cli::Credentials.read(site)
          if credentials.blank? || credentials[0].blank? || credentials[1].blank?
            say "Please run 'oo auth login' command first to login.".red
            return false
          end
          OO::Api::Config.send("#{:user}=", credentials[0])
          OO::Api::Config.send("#{:password}=", credentials[1])

          return true
        end


        private

        def get_value(name)
          @in_place[name] || @local[name] || @global[name]
        end

        def save(global)
          File.open(global ? GLOBAL_FILE_NAME : LOCAL_FILE_NAME, 'w') {|f| f.write((global ? @global : @local).to_yaml)}
        end
      end

      @global   = File.exist?(GLOBAL_FILE_NAME) ? YAML.load_file(GLOBAL_FILE_NAME) : {}
      @local    = File.exist?(LOCAL_FILE_NAME)  ? YAML.load_file(LOCAL_FILE_NAME)  : {}
      @in_place = {}
    end
  end
end
