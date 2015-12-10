require 'rubygems'
require 'active_support/core_ext'
require 'rest_client'

ROOT = File.expand_path(File.dirname(__FILE__))
module OO
  module Api
    class ApiException < Exception
    end
    class UnauthroizedException < ApiException
    end
    class NotFoundException < ApiException
    end

    autoload :Config, "#{ROOT}/api/config"

    Dir.glob(File.join(ROOT, 'api', '*.rb')).each do |file|
      autoload file.split(File::SEPARATOR).last.split('.rb').first.capitalize, file
    end

    %w(account cloud design transition operations).each do |scope|
      scope_module = const_set(scope.capitalize, Module.new)
      Dir.glob(File.join(ROOT, 'api', scope, '/*.rb')).each do |file|
        scope_module.autoload(file.split(File::SEPARATOR).last.split('.rb').first.capitalize, file)
      end
    end
  end
end
