# frozen_string_literal: true

module RailsSimpleEventSourcing
  module Commands
    class Base
      include ActiveModel::Model

      attr_accessor :aggregate_id
    end
  end
end
