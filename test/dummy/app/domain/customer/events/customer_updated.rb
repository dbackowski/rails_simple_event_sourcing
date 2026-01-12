class Customer
  module Events
    class CustomerUpdated < RailsSimpleEventSourcing::Event
      aggregate_class Customer
      event_attributes :first_name, :last_name, :email, :updated_at
    end
  end
end
