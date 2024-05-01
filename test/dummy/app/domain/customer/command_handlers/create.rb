class Customer
  module CommandHandlers
    class Create < RailsSimpleEventSourcing::CommandHandlers::Base
      def call
        event = Customer::Events::CustomerCreated.create(
          first_name: @command.first_name,
          last_name: @command.last_name,
          created_at: Time.zone.now,
          updated_at: Time.zone.now
        )

        RailsSimpleEventSourcing::Result.new(success?: true, data: event.eventable)
      end
    end
  end
end
