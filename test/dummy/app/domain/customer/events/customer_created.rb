class Customer
  module Events
    class CustomerCreated < RailsSimpleEventSourcing::Event
      aggregate_class Customer
      event_attributes :first_name, :last_name, :email, :created_at, :updated_at
    end
  end
end
