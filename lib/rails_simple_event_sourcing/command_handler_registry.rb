# frozen_string_literal: true

module RailsSimpleEventSourcing
  class CommandHandlerRegistry
    CommandAlreadyRegisteredError = Class.new(StandardError)

    @registry = Concurrent::Map.new

    def self.register(command_class, handler_class)
      if @registry.key?(command_class)
        raise CommandAlreadyRegisteredError, "Command handler already registered for #{command_class}"
      end

      @registry[command_class] = handler_class
    end

    def self.handler_for(command_class)
      @registry[command_class]
    end
  end
end
