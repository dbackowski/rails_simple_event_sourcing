class Customer
  module Events
    class CustomerCreated < RailsSimpleEventSourcing::Event
      aggregate_class Customer
      event_attributes :first_name, :last_name, :email, :created_at, :updated_at

      def apply(aggregate)
        aggregate.id = aggregate_id
        aggregate.first_name = first_name
        aggregate.last_name = last_name
        aggregate.email = email
        aggregate.created_at = created_at
        aggregate.updated_at = updated_at
      end
    end
  end
end
