# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LearnGitlabHelper do
  include AfterNextHelpers
  include Devise::Test::ControllerHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, name: LearnGitlab::PROJECT_NAME, namespace: user.namespace) }
  let_it_be(:namespace) { project.namespace }

  before do
    project.add_developer(user)

    allow(helper).to receive(:user).and_return(user)
    allow_next_instance_of(LearnGitlab) do |learn_gitlab|
      allow(learn_gitlab).to receive(:project).and_return(project)
    end

    OnboardingProgress.onboard(namespace)
    OnboardingProgress.register(namespace, :git_write)
  end

  describe '.onboarding_actions_data' do
    subject(:onboarding_actions_data) { helper.onboarding_actions_data(project) }

    it 'has all actions' do
      expect(onboarding_actions_data.keys).to contain_exactly(
        :git_write,
        :pipeline_created,
        :merge_request_created,
        :user_added,
        :trial_started,
        :required_mr_approvals_enabled,
        :code_owners_enabled,
        :security_scan_enabled
      )
    end

    it 'sets correct path and completion status' do
      expect(onboarding_actions_data[:git_write]).to eq({
        url: project_issue_url(project, LearnGitlabHelper::ACTION_ISSUE_IDS[:git_write]),
        completed: true
      })
      expect(onboarding_actions_data[:pipeline_created]).to eq({
        url: project_issue_url(project, LearnGitlabHelper::ACTION_ISSUE_IDS[:pipeline_created]),
        completed: false
      })
    end
  end

  describe '.learn_gitlab_experiment_enabled?' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, namespace: user.namespace) }

    let(:params) { { namespace_id: project.namespace.to_param, project_id: project } }

    subject { helper.learn_gitlab_experiment_enabled?(project) }

    where(:experiment_a, :experiment_b, :onboarding, :learn_gitlab_available, :result) do
      true        | false         | true        | true                  | true
      false       | true          | true        | true                  | true
      false       | false         | true        | true                  | false
      true        | true          | true        | false                 | false
      true        | true          | false       | true                  | false
    end

    with_them do
      before do
        stub_experiment_for_subject(learn_gitlab_a: experiment_a, learn_gitlab_b: experiment_b)
        allow(OnboardingProgress).to receive(:onboarding?).with(project.namespace).and_return(onboarding)
        allow_next(LearnGitlab, user).to receive(:available?).and_return(learn_gitlab_available)
      end

      context 'when signed in' do
        before do
          sign_in(user)
        end

        it { is_expected.to eq(result) }
      end

      context 'when not signed in' do
        it { is_expected.to eq(false) }
      end
    end
  end
end
