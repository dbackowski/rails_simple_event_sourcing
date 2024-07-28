module RailsSimpleEventSourcing
  module Events
    extend ActiveSupport::Concern

    included do
      has_many :events, class_name: 'RailsSimpleEventSourcing::Event', as: :eventable, dependent: :nullify

      def readonly?
        !@write_access_enabled
      end

      def enable_write_access!
        @write_access_enabled = true
      end
    end
  end
end
