# frozen_string_literal: true

module RailsSimpleEventSourcing
  module EventAttributes
    extend ActiveSupport::Concern

    class_methods do
      def event_attributes(*attributes)
        attributes.each do |attribute|
          define_payload_accessor(attribute)
        end
      end

      private

      def define_payload_accessor(attribute)
        define_method(attribute) do
          self.payload ||= {}
          self.payload[attribute.to_s]
        end

        define_method("#{attribute}=") do |value|
          self.payload ||= {}
          self.payload[attribute.to_s] = value
        end
      end
    end
  end
end
