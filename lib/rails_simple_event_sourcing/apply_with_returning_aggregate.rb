# frozen_string_literal: true

module RailsSimpleEventSourcing
  module ApplyWithReturningAggregate
    def apply(aggregate)
      aggregate.tap { super }
    end
  end
end
