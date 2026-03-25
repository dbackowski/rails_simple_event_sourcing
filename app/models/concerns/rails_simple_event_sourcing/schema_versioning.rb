# frozen_string_literal: true

module RailsSimpleEventSourcing
  module SchemaVersioning
    extend ActiveSupport::Concern

    class_methods do
      def current_version(version)
        @current_schema_version = version
      end

      def schema_version_number
        @current_schema_version || 1
      end

      def upcaster(from_version, &block)
        upcasters[from_version] = block
      end

      def upcasters
        @upcasters ||= {}
      end
    end

    included do
      before_validation :set_schema_version, on: :create
    end

    def payload
      data = super
      return data if new_record?

      upcast(data)
    end

    private

    def upcast(data)
      return data if data.nil? || schema_version.nil?

      current = schema_version
      target = self.class.schema_version_number

      while current < target
        upcaster = self.class.upcasters[current]
        raise "Missing upcaster from version #{current} to #{current + 1} for #{self.class}" unless upcaster

        data = upcaster.call(data)
        current += 1
      end

      data
    end

    def set_schema_version
      return unless aggregate_defined?

      self.schema_version = self.class.schema_version_number
    end
  end
end
