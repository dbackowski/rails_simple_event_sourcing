# frozen_string_literal: true

module RailsSimpleEventSourcing
  class CurrentRequest < ActiveSupport::CurrentAttributes
    attribute :metadata
  end
end
