# frozen_string_literal: true

module RailsSimpleEventSourcing
  class EventBus
    @subscriptions = Concurrent::Map.new { |h, k| h[k] = Concurrent::Array.new }

    class << self
      def subscribe(event_class, subscriber)
        @subscriptions[event_class.to_s] << subscriber
      end

      def dispatch(event)
        ancestors_with_subscriptions(event).each do |subscriber|
          subscriber.call(event)
        end
      end

      def reset!
        @subscriptions = Concurrent::Map.new { |h, k| h[k] = Concurrent::Array.new }
      end

      private

      def ancestors_with_subscriptions(event)
        event.class.ancestors
             .select { |ancestor| @subscriptions.key?(ancestor.to_s) }
             .flat_map { |ancestor| @subscriptions[ancestor.to_s] }
      end
    end
  end
end
