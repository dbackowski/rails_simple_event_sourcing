class Customer
  module CommandHandlers
    class Delete < RailsSimpleEventSourcing::CommandHandlers::Base
      def call
        Customer::Events::CustomerDeleted.create(
          aggregate_id: @command.aggregate_id,
          deleted_at: Time.zone.now
        )

        RailsSimpleEventSourcing::Result.new(success?: true)
      end
    end
  end
end
