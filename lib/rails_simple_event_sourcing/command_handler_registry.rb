# frozen_string_literal: true

module RailsSimpleEventSourcing
  class CommandHandlerRegistry
    class CommandAlreadyRegisteredError < StandardError
    end

    @registry = Concurrent::Map.new

    def self.register(command_class, handler_class)
      if @registry.key?(command_class)
        raise CommandAlreadyRegisteredError, "Command handler already registered for #{command_class}"
      end

      @registry[command_class] = handler_class
    end

    def self.deregister(command_class)
      @registry.delete(command_class)
    end

    def self.handler_for(command_class)
      @registry[command_class]
    end
  end
end
