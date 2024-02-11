class Customer
  module Events
    class CustomerUpdated < RailsSimpleEventSourcing::Event
      aggregate_model_name Customer
      event_attributes :first_name, :last_name, :updated_at

      def apply(aggregate)
        aggregate.first_name = first_name
        aggregate.last_name = last_name
        aggregate.updated_at = updated_at
      end
    end
  end
end
