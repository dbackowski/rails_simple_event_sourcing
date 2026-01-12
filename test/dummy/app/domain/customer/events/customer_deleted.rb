class Customer
  module Events
    class CustomerDeleted < RailsSimpleEventSourcing::Event
      aggregate_class Customer
      event_attributes :deleted_at
    end
  end
end
