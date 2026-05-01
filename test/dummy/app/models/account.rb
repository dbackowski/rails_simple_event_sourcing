class Account < ApplicationRecord
  include RailsSimpleEventSourcing::Events
end
