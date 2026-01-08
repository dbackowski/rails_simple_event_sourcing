# frozen_string_literal: true

module RailsSimpleEventSourcing
  module AggregateConfiguration
    extend ActiveSupport::Concern

    class_methods do
      def aggregate_model_name(name = nil)
        if name
          @aggregate_model_name = name
        else
          @aggregate_model_name
        end
      end

      def aggregate_model_class
        aggregate_model_name&.constantize
      end
    end

    def aggregate_model_name
      self.class.aggregate_model_name.to_s
    end

    def aggregate_model_class
      self.class.aggregate_model_class
    end

    def aggregate_defined?
      aggregate_model_name.present?
    end
  end
end
