# frozen_string_literal: true

module AppSec
  module Dast
    module Scans
      class RunService < BaseService
        def execute(branch:, ci_configuration:, dast_profile: nil, dast_site_profile: nil, dast_scanner_profile: nil)
          return ServiceResponse.error(message: 'Insufficient permissions') unless allowed?

          service = Ci::CreatePipelineService.new(project, current_user, ref: branch)

          response = service.execute(:ondemand_dast_scan, content: ci_configuration) do |pipeline|
            pipeline.dast_profile = dast_profile
          end

          pipeline = response.payload
          if pipeline.created_successfully?
            ServiceResponse.success(payload: pipeline)
          else
            ServiceResponse.error(message: pipeline.full_error_messages)
          end
        end

        private

        def allowed?
          Ability.allowed?(current_user, :create_on_demand_dast_scan, project)
        end
      end
    end
  end
end
