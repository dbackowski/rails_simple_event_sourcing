# frozen_string_literal: true

module RailsSimpleEventSourcing
  class EventBus
    @subscriptions = Concurrent::Map.new { |h, k| h[k] = Concurrent::Array.new }

    class << self
      def subscribe(event_class, subscriber)
        unless subscriber.is_a?(Class) && subscriber < ActiveJob::Base
          raise ArgumentError, "Subscriber must be an ActiveJob class, got #{subscriber}"
        end

        @subscriptions[event_class.to_s] << subscriber
      end

      def dispatch(event)
        subscribers_for(event).each do |subscriber|
          subscriber.perform_later(event)
        rescue StandardError => e
          Rails.logger.error(
            "[RailsSimpleEventSourcing::EventBus] Failed to enqueue #{subscriber} for event ##{event.id}: #{e.message}"
          )
        end
      end

      def reset!
        @subscriptions = Concurrent::Map.new { |h, k| h[k] = Concurrent::Array.new }
      end

      private

      def subscribers_for(event)
        event.class.ancestors
             .select { |ancestor| @subscriptions.key?(ancestor.to_s) }
             .flat_map { |ancestor| @subscriptions[ancestor.to_s] }
      end
    end
  end
end
