module RailsSimpleEventSourcing
  module Commands
    class Base
      include ActiveModel::Model
      include ActiveModel::Validations

      attr_accessor :aggregate_id
    end
  end
end
