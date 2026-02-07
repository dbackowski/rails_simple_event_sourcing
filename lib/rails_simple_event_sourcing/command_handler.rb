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
        @convention_handler_name = @command.class.to_s.sub('::Commands::', '::CommandHandlers::')
        handler_class = @convention_handler_name.safe_constantize
      end

      handler_class
    end

    def handler_not_found_message
      message = "No handler found for #{@command.class}."
      message += " Tried convention-based lookup: #{@convention_handler_name} (not found)." if @convention_handler_name
      message += " Register one with CommandHandlerRegistry.register(#{@command.class}, YourHandlerClass)"
      message
    end
  end
end
