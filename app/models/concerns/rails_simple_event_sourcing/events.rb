# frozen_string_literal: true

module RailsSimpleEventSourcing
  module Events
    extend ActiveSupport::Concern
    include ReadOnly

    included do
      has_many :events, class_name: 'RailsSimpleEventSourcing::Event', as: :eventable, dependent: :nullify
    end
  end
end
