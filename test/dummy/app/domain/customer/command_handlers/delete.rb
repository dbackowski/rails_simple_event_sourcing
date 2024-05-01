class Customer
  module CommandHandlers
    class Delete < RailsSimpleEventSourcing::CommandHandlers::Base
      def call
        event = Customer::Events::CustomerDeleted.create(
          aggregate_id: @command.aggregate_id,
          deleted_at: Time.zone.now
        )

        RailsSimpleEventSourcing::Result.new(success?: true, data: event.eventable)
      end
    end
  end
end
