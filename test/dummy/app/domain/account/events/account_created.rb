class Account
  module Events
    class AccountCreated < RailsSimpleEventSourcing::Event
      aggregate_class Account
      event_attributes :name, :created_at, :updated_at
    end
  end
end