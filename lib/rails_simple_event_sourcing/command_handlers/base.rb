module RailsSimpleEventSourcing
  module CommandHandlers
    class Base
      def initialize(command:)
        @command = command
      end

      def call
        raise NotImplementedError
      end
    end
  end
end
