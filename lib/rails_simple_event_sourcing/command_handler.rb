module RailsSimpleEventSourcing
  class CommandHandler
    def initialize(command)
      @command = command
    end

    def call
      return unless @command.valid?

      command_hander = initialize_command_handler
      command_hander.call
    end

    private

    def initialize_command_handler
      @command.class.to_s.gsub("::Commands::", "::CommandHandlers::").constantize.new(command: @command)
    end
  end
end
