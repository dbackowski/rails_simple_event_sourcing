# frozen_string_literal: true

module RailsSimpleEventSourcing
  class CommandHandler
    class CommandHandlerNotFoundError < StandardError; end

    def initialize(command)
      @command = command
    end

    def call
      return Result.new(success?: false, errors: @command.errors) unless @command.valid?

      initialize_command_handler.call
    end

    private

    def initialize_command_handler
      handler_class_name = @command.class.to_s.gsub('::Commands::', '::CommandHandlers::')
      handler_class = handler_class_name.safe_constantize
      raise CommandHandlerNotFoundError, "Handler #{handler_class_name} not found" unless handler_class

      handler_class.new(command: @command)
    end
  end
end
