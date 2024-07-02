module RailsSimpleEventSourcing
  class CommandHandler
    def initialize(command)
      @command = command
    end

    def call
      return Result.new(success?: false, errors: @command.errors) unless @command.valid?

      initialize_command_handler.call
      Result.new(success?: true)
    end

    private

    def initialize_command_handler
      @command.class.to_s.gsub("::Commands::", "::CommandHandlers::").constantize.new(command: @command)
    end
  end
end
