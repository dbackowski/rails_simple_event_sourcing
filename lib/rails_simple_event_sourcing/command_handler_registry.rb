# frozen_string_literal: true

module RailsSimpleEventSourcing
  class CommandHandlerRegistry
    def self.register(command_class, handler_class)
      registry[command_class] = handler_class
    end

    def self.handler_for(command_class)
      registry[command_class]
    end

    def self.registry
      @registry ||= {}
    end

    def self.clear
      @registry = {}
    end
  end
end
