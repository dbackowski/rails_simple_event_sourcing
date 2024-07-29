# frozen_string_literal: true

module RailsSimpleEventSourcing
  module CommandHandlers
    class Base
      def initialize(command:)
        @command = command
      end

      def call
        raise NoMethodError, "You must implement #{self.class}#call"
      end
    end
  end
end
