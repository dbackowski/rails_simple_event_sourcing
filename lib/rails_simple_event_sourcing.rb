# frozen_string_literal: true

require 'rails_simple_event_sourcing/version'
require 'rails_simple_event_sourcing/engine'
require 'rails_simple_event_sourcing/configuration'
require 'rails_simple_event_sourcing/command_handler_registry'

module RailsSimpleEventSourcing
  def self.configure
    yield(config) if block_given?
    config
  end

  def self.config
    @config ||= Configuration.new
  end
end
