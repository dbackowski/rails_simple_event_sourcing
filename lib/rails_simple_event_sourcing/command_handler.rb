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
      handler_class = find_handler_class
      raise CommandHandlerNotFoundError, handler_not_found_message unless handler_class

      handler_class.new(command: @command)
    end

    def find_handler_class
      handler_class = CommandHandlerRegistry.handler_for(@command.class)

      if handler_class.nil? && RailsSimpleEventSourcing.config.use_naming_convention_fallback
        handler_class_name = @command.class.to_s.gsub('::Commands::', '::CommandHandlers::')
        handler_class = handler_class_name.safe_constantize
      end

      handler_class
    end

    def handler_not_found_message
      "No handler registered for #{@command.class}. " \
        "Register one with CommandHandlerRegistry.register(#{@command.class}, YourHandlerClass)"
    end
  end
end
