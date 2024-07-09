class Customer
  module Events
    class CustomerEmailTaken < RailsSimpleEventSourcing::Event
      event_attributes :first_name, :last_name, :email
    end
  end
end
