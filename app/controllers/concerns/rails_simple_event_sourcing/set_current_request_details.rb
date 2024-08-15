# frozen_string_literal: true

module RailsSimpleEventSourcing
  module SetCurrentRequestDetails
    extend ActiveSupport::Concern

    included do
      before_action :set_event_metadata

      private

      def set_event_metadata
        CurrentRequest.metadata = event_metadata
      end

      def event_metadata
        parameter_filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)

        {
          request_id: request.uuid,
          request_user_agent: request.user_agent,
          request_referer: request.referer,
          request_ip: request.ip,
          request_params: parameter_filter.filter(request.params)
        }
      end
    end
  end
end
