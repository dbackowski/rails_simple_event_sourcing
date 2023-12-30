module RailsSimpleEventSourcing
  module ApplyWithReturningAggregate
    def apply(aggregate)
      aggregate.tap { super }
    end
  end
end
