class Customer
  module CommandHandlers
    class Create < RailsSimpleEventSourcing::CommandHandlers::Base
      def call
        event = Customer::Events::CustomerCreated.create(
          first_name: @command.first_name,
          last_name: @command.last_name,
          email: @command.email,
          created_at: Time.zone.now,
          updated_at: Time.zone.now
        )

        RailsSimpleEventSourcing::Result.new(success?: true, data: event.aggregate)
      rescue ActiveRecord::RecordNotUnique
        event = Customer::Events::CustomerEmailTaken.create(
          first_name: @command.first_name,
          last_name: @command.last_name,
          email: @command.email
        )

        RailsSimpleEventSourcing::Result.new(success?: false, errors: { email: ['already taken'] })
      end
    end
  end
end
