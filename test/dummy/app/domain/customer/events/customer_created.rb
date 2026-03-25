class Customer
  module Events
    class CustomerCreated < RailsSimpleEventSourcing::Event
      aggregate_class Customer
      current_version 2
      event_attributes :first_name, :last_name, :email, :created_at, :updated_at

      # v1 had a single "name" field, v2 splits it into first_name and last_name
      upcaster(1) do |payload|
        if payload.key?('name')
          parts = payload.delete('name').to_s.split(' ', 2)
          payload['first_name'] = parts[0]
          payload['last_name'] = parts[1]
        end
        payload
      end
    end
  end
end
