class Customer < ApplicationRecord
  include RailsSimpleEventSourcing::Events
end
