# frozen_string_literal: true

module RailsSimpleEventSourcing
  class CommandHandler
    class CommandHandlerNotFoundError < StandardError; end

    def initialize(command)
      @command = command
    end

    def call
      return Result.failure(errors: @command.errors) unless @command.valid?

      build_handler.call
    end

    private

    def build_handler
      handler_class = find_handler_class
      raise CommandHandlerNotFoundError, handler_not_found_message unless handler_class

      handler_class.new(command: @command)
    end

    def find_handler_class
      CommandHandlerRegistry.handler_for(@command.class) || convention_handler_class
    end

    def convention_handler_class
      return unless RailsSimpleEventSourcing.config.use_naming_convention_fallback

      convention_handler_name.safe_constantize
    end

    def convention_handler_name
      @convention_handler_name ||= @command.class.to_s.sub('::Commands::', '::CommandHandlers::')
    end

    def handler_not_found_message
      msg = "No handler found for #{@command.class}."
      if RailsSimpleEventSourcing.config.use_naming_convention_fallback
        msg += " Tried convention-based lookup: #{convention_handler_name} (not found)."
      end
      msg + " Register one with CommandHandlerRegistry.register(#{@command.class}, YourHandlerClass)"
    end
  end
end
