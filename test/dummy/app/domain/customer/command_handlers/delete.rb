class Customer
  module CommandHandlers
    class Delete < RailsSimpleEventSourcing::CommandHandlers::Base
      def call
        Customer::Events::CustomerDeleted.create!(
          aggregate_id: @command.aggregate_id,
          deleted_at: Time.zone.now
        )

        success_result
      end
    end
  end
end
