# frozen_string_literal: true

module RailsSimpleEventSourcing
  module CommandHandlers
    class Base
      def initialize(command:)
        @command = command
      end

      def call
        raise NotImplementedError, "You must implement #{self.class}#call"
      end

      private

      attr_reader :command

      def success(data: nil)
        Result.success(data:)
      end

      def failure(errors:)
        Result.failure(errors:)
      end
    end
  end
end
