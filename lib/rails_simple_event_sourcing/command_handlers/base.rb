# frozen_string_literal: true

module RailsSimpleEventSourcing
  module CommandHandlers
    class Base
      delegate :success, :failure, to: 'RailsSimpleEventSourcing::Result'

      def initialize(command:)
        @command = command
      end

      def call
        raise NotImplementedError, "You must implement #{self.class}#call"
      end
    end
  end
end
