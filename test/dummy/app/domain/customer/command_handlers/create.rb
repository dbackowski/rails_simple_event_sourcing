class Customer
  module CommandHandlers
    class Create < RailsSimpleEventSourcing::CommandHandlers::Base
      def call
        Customer::Events::CustomerCreated.create(
          aggregate_id: @command.aggregate_id,
          first_name: @command.first_name,
          last_name: @command.last_name,
          created_at: Time.zone.now,
          updated_at: Time.zone.now
        )
      end
    end
  end
end
