module RailsSimpleEventSourcing
  module Events
    extend ActiveSupport::Concern

    included do
      has_many :events, class_name: 'RailsSimpleEventSourcing::Event', as: :eventable, dependent: :nullify
    end
  end
end
