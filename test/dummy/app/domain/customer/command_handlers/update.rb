class Customer
  module CommandHandlers
    class Update < RailsSimpleEventSourcing::CommandHandlers::Base
      def call
        event = Customer::Events::CustomerUpdated.create(
          aggregate_id: @command.aggregate_id,
          first_name: @command.first_name,
          last_name: @command.last_name,
          updated_at: Time.zone.now
        )

        RailsSimpleEventSourcing::Result.new(success?: true, data: event.aggregate)
      end
    end
  end
end
