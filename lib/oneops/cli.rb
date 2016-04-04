require File.expand_path('../api', __FILE__)

require 'netrc'
require 'rbconfig'

WINDOWS = !!(RbConfig::CONFIG['host_os'] =~ /mingw|mswin32|cygwin/)

module OO
  module Cli
    autoload :Config,      "#{ROOT}/cli/config"
    autoload :Credentials, "#{ROOT}/cli/credentials"
    autoload :Runner,      "#{ROOT}/cli/runner"

    module Command
      Dir.glob(File.join(ROOT, 'cli', 'commands', '*.rb')).each do |command|
        autoload command.split(File::SEPARATOR).last.split('.rb').first.capitalize, command
      end

      %w(account cloud design transition operations).each do |scope|
        scope_class = const_get(scope.capitalize)
        Dir.glob(File.join(ROOT, 'cli', 'commands', scope, '*.rb')).each do |command|
          scope_class.autoload(command.split(File::SEPARATOR).last.split('.rb').first.capitalize, command)
        end
      end
    end
  end
end

require "#{ROOT}/cli/display"
require "#{ROOT}/version"

OO::Cli::Config.colorize = true
if WINDOWS
  begin
    require 'Win32/Console/ANSI'
  rescue Exception => e
    OO::Cli::Config.colorize = false
  end
end
OO::Cli::Config.output = $stdout
