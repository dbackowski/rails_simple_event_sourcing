# frozen_string_literal: true

module RailsSimpleEventSourcing
  class EventSearch
    KEY_VALUE_PATTERN = /\A([^:]+):(.+)\z/

    def initialize(scope:, type: nil, aggregate: nil, query: nil)
      @scope = scope
      @type = type
      @aggregate = aggregate
      @query = query&.strip
    end

    def call
      filter_by_type
      filter_by_aggregate
      filter_by_query
      @scope
    end

    private

    def filter_by_type
      return if @type.blank?

      @scope = @scope.where(type: @type)
    end

    def filter_by_aggregate
      return if @aggregate.blank?

      @scope = @scope.where(eventable_type: @aggregate)
    end

    def filter_by_query
      return if @query.blank?

      if (match = @query.match(KEY_VALUE_PATTERN))
        filter_by_key_value(match[1], match[2])
      else
        filter_by_aggregate_id(@query)
      end
    end

    def filter_by_key_value(key, value)
      json_fragment = { key => value }.to_json
      @scope = @scope.where(
        'payload @> :json::jsonb OR metadata @> :json::jsonb',
        json: json_fragment
      )
    end

    def filter_by_aggregate_id(value)
      @scope = @scope.where(aggregate_id: value)
    end
  end
end
