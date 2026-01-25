# frozen_string_literal: true

module RailsSimpleEventSourcing
  module ReadOnly
    extend ActiveSupport::Concern

    included do
      def readonly?
        super || !write_access_enabled
      end

      def enable_write_access!
        @write_access_enabled = true
      end

      private

      def write_access_enabled
        @write_access_enabled ||= false
      end
    end
  end
end
