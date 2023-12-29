module RailsSimpleEventSourcing
  module Events
    class Base
      include ActiveModel::Model
      include ActiveModel::Serialization
      extend ActiveModel::Callbacks

      define_model_callbacks :initialize
      after_initialize :apply_and_persist

      attr_accessor :aggregate_id

      def self.aggregate_class_name(name)
        self.singleton_class.instance_variable_set(:@aggregate_class_name, name)
      end

      def aggregate_class_name
        self.class.singleton_class.instance_variable_get(:@aggregate_class_name)
      end

      def initialize(attributes={})
        @attributes = attributes

        run_callbacks :initialize do
          super(attributes)
        end
      end

      def attributes
        @attributes
      end

      # each event has to define its own apply method
      def apply
        raise NotImplementedError
      end

      private

      def apply_and_persist
        ActiveRecord::Base.transaction do
          aggregate = find_or_build_aggregate
          aggregate.lock! if aggregate.persisted?
          apply(aggregate)
          aggregate.save!

          Event.create!(event_type: self.class, aggregate_id: aggregate.id, payload: self.serializable_hash, eventable: aggregate)
        end
      end

      def find_or_build_aggregate
        return aggregate_class_name.find(aggregate_id) if aggregate_id.present?

        aggregate_class_name.new
      end
    end
  end
end
