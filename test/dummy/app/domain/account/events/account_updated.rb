class Account
  module Events
    class AccountUpdated < RailsSimpleEventSourcing::Event
      aggregate_class Account
      event_attributes :name, :updated_at
    end
  end
end
