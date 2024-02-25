class Customer
  module Events
    class CustomerDeleted < RailsSimpleEventSourcing::Event
      aggregate_model_name Customer
      event_attributes :deleted_at

      def apply(aggregate)
        aggregate.deleted_at = deleted_at
      end
    end
  end
end
