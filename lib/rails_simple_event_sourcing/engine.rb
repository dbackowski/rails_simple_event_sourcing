require_relative 'command_handlers/base'
require_relative 'commands/base'
require_relative 'command_handler'
require_relative 'apply_with_returning_aggregate'
require_relative 'result'

module RailsSimpleEventSourcing
  class Engine < ::Rails::Engine
    isolate_namespace RailsSimpleEventSourcing
  end
end
