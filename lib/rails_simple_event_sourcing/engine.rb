require_relative 'command_handlers/base'
require_relative 'commands/base'
require_relative 'events/base'
require_relative 'command_handler'

module RailsSimpleEventSourcing
  class Engine < ::Rails::Engine
  end
end
