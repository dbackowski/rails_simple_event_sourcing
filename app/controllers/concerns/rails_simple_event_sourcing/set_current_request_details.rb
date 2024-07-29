# frozen_string_literal: true

module RailsSimpleEventSourcing
  module SetCurrentRequestDetails
    extend ActiveSupport::Concern

    included do
      before_action do
        parameter_filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)

        CurrentRequest.request_id = request.uuid
        CurrentRequest.request_user_agent = request.user_agent
        CurrentRequest.request_referer = request.referer
        CurrentRequest.request_ip = request.ip
        CurrentRequest.request_params = parameter_filter.filter(request.params)
      end
    end
  end
end
