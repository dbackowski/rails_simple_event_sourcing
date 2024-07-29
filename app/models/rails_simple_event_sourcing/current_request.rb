# frozen_string_literal: true

module RailsSimpleEventSourcing
  class CurrentRequest < ActiveSupport::CurrentAttributes
    attribute :request_id, :request_referer, :request_user_agent, :request_params, :request_ip
  end
end
