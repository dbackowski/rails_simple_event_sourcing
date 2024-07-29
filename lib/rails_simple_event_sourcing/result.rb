# frozen_string_literal: true

module RailsSimpleEventSourcing
  Result = Struct.new(:success?, :data, :errors, keyword_init: true)
end
