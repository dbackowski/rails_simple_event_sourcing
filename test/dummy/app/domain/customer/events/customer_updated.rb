class Customer
  module Events
    class CustomerUpdated < RailsSimpleEventSourcing::Event
      aggregate_class Customer
      event_attributes :first_name, :last_name, :email, :updated_at

      def apply(aggregate)
        aggregate.first_name = first_name
        aggregate.last_name = last_name
        aggregate.email = email if email.present?
        aggregate.updated_at = updated_at
      end
    end
  end
end
