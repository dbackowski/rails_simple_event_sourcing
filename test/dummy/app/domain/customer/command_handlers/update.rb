class Customer
  module CommandHandlers
    class Update < RailsSimpleEventSourcing::CommandHandlers::Base
      def call
        Customer::Events::CustomerUpdated.create(
          aggregate_id: @command.aggregate_id,
          first_name: @command.first_name,
          last_name: @command.last_name,
          updated_at: Time.zone.now
        )
      end
    end
  end
end
