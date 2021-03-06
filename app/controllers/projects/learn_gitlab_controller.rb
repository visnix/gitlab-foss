# frozen_string_literal: true

class Projects::LearnGitlabController < Projects::ApplicationController
  before_action :authenticate_user!
  before_action :check_experiment_enabled?

  feature_category :users

  def index
  end

  private

  def check_experiment_enabled?
    return access_denied! unless helpers.learn_gitlab_enabled?(project)
  end
end
