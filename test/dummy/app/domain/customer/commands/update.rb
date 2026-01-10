class Customer
  module Commands
    class Update < RailsSimpleEventSourcing::Commands::Base
      attr_accessor :first_name, :last_name, :email

      validates :first_name, presence: true
      validates :last_name, presence: true
    end
  end
end
