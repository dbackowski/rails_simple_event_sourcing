# frozen_string_literal: true

module RailsSimpleEventSourcing
  module AggregateConfiguration
    extend ActiveSupport::Concern

    class_methods do
      def aggregate_class(name = nil)
        return @aggregate_class if name.nil?

        @aggregate_class = name
      end
    end

    delegate :aggregate_class, to: :class

    def aggregate_defined?
      aggregate_class.present?
    end
  end
end
