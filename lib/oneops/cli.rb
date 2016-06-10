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

# This "hack" is to disable redundant and confusing option completion ("fuzy" matching) feature for short switches
# because it messes up switch propagation throughout our command chain.  For example, in this command:
#     oo design component show -a Lev -p web -c compute
# the '-c ...' option ()used to specify component name) will never get to 'component' command because it will be
# picked off first by 'design' command option parser due its having a long '--comment [TEXT]' long option defined.
# This is because OptParser tries to auto complete and match what it considers incomplete "-c" switch to a known long
# switch '--comment'.  OptParser should NOT have this behavior by default and it should be at least configurable.

class OptionParser
  alias :complete_original :complete

  def complete(typ, opt, icase = false, *pat)
    if typ.to_s == 'long' && !icase
      raise OptionParser::InvalidOption, opt
    else
      complete_original(typ, opt, icase, *pat)
    end
  end
end
