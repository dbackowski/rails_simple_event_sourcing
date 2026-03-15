class Customer
  module CommandHandlers
    class Create < RailsSimpleEventSourcing::CommandHandlers::Base
      def call
        event = Customer::Events::CustomerCreated.create!(
          first_name: command.first_name,
          last_name: command.last_name,
          email: command.email,
          created_at: Time.zone.now,
          updated_at: Time.zone.now
        )

        success(data: event.aggregate)
      rescue ActiveRecord::RecordNotUnique
        Customer::Events::CustomerEmailTaken.create!(
          first_name: command.first_name,
          last_name: command.last_name,
          email: command.email
        )

        failure(errors: { email: ['already taken'] })
      end
    end
  end
end
