# frozen_string_literal: true

require_relative 'aggregate_repository'
require_relative 'command_handler'
require_relative 'command_handlers/base'
require_relative 'commands/base'
require_relative 'event_applicator'
require_relative 'event_player'
require_relative 'result'
require_relative 'command_handler_registry'

module RailsSimpleEventSourcing
  class Engine < ::Rails::Engine
    isolate_namespace RailsSimpleEventSourcing
  end
end
