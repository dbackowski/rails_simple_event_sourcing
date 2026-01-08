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

      def success_result(data: nil)
        RailsSimpleEventSourcing::Result.new(success?: true, data:)
      end

      def failure_result(errors:)
        RailsSimpleEventSourcing::Result.new(success?: false, errors:)
      end
    end
  end
end
