# frozen_string_literal: true

module Groups
  class UpdateSharedRunnersService < Groups::BaseService
    def execute
      return error('Operation not allowed', 403) unless can?(current_user, :admin_group, group)

      validate_params

      update_shared_runners
      update_pending_builds!

      success

    rescue ActiveRecord::RecordInvalid, ArgumentError => error
      error(error.message)
    end

    private

    def validate_params
      unless Namespace::SHARED_RUNNERS_SETTINGS.include?(params[:shared_runners_setting])
        raise ArgumentError, "state must be one of: #{Namespace::SHARED_RUNNERS_SETTINGS.join(', ')}"
      end
    end

    def update_shared_runners
      group.update_shared_runners_setting!(params[:shared_runners_setting])
    end

    def update_pending_builds!
      return unless group.previous_changes.include?('shared_runners_enabled')

      update_params = { instance_runners_enabled: group.shared_runners_enabled }

      ::Ci::UpdatePendingBuildService.new(group, update_params).execute
    end
  end
end
