# frozen_string_literal: true

class Customer
  module Subscribers
    class Notifier < ActiveJob::Base
      cattr_accessor :received_event_ids, default: []

      def perform(event)
        received_event_ids << event.id
      end

      def self.reset!
        self.received_event_ids = []
      end
    end
  end
end
