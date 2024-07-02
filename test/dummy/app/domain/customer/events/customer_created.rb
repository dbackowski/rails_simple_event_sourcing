class Customer
  module Events
    class CustomerCreated < RailsSimpleEventSourcing::Event
      aggregate_model_name Customer
      event_attributes :first_name, :last_name, :created_at, :updated_at

      def apply(aggregate)
        aggregate.id = aggregate_id
        aggregate.first_name = first_name
        aggregate.last_name = last_name
        aggregate.created_at = created_at
        aggregate.updated_at = updated_at
      end
    end
  end
end
