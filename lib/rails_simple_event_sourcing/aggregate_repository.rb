# frozen_string_literal: true

module RailsSimpleEventSourcing
  class AggregateRepository
    def initialize(aggregate_class)
      @aggregate_class = aggregate_class
    end

    def find_or_build(aggregate_id)
      if aggregate_id.present?
        find_with_lock(aggregate_id)
      else
        build_new
      end
    end

    def save!(aggregate)
      aggregate.enable_write_access!
      aggregate.save!
    end

    private

    def find_with_lock(aggregate_id)
      @aggregate_class.find(aggregate_id).lock!
    end

    def build_new
      @aggregate_class.new
    end
  end
end
