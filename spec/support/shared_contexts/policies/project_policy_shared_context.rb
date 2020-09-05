# frozen_string_literal: true

RSpec.shared_context 'ProjectPolicy context' do
  let_it_be(:guest) { create(:user) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:owner) { create(:user) }
  let_it_be(:admin) { create(:admin) }
  let(:project) { create(:project, :public, namespace: owner.namespace) }

  let(:base_guest_permissions) do
    %i[
      award_emoji create_issue create_merge_request_in create_note
      create_project read_board read_issue read_issue_iid read_issue_link
      read_label read_list read_milestone read_note read_project
      read_project_for_iids read_project_member read_release read_snippet
      read_wiki upload_file
    ]
  end

  let(:base_reporter_permissions) do
    %i[
      admin_issue admin_issue_link admin_label admin_list create_snippet
      download_code download_wiki_code fork_project metrics_dashboard
      read_build read_commit_status read_confidential_issues
      read_container_image read_deployment read_environment read_merge_request
      read_metrics_dashboard_annotation read_pipeline read_prometheus
      read_sentry_issue update_issue
    ]
  end

  let(:team_member_reporter_permissions) do
    %i[build_download_code build_read_container_image]
  end

  let(:developer_permissions) do
    %i[
      admin_milestone admin_merge_request update_merge_request create_commit_status
      update_commit_status create_build update_build create_pipeline
      update_pipeline create_merge_request_from create_wiki push_code
      resolve_note create_container_image update_container_image
      create_environment create_deployment update_deployment create_release update_release
      update_environment daily_statistics
    ]
  end

  let(:base_maintainer_permissions) do
    %i[
      push_to_delete_protected_branch update_snippet
      admin_snippet admin_project_member admin_note admin_wiki admin_project
      admin_commit_status admin_build admin_container_image
      admin_pipeline admin_environment admin_deployment destroy_release add_cluster
    ]
  end

  let(:public_permissions) do
    %i[
      download_code fork_project read_commit_status read_pipeline
      read_container_image build_download_code build_read_container_image
      download_wiki_code read_release
    ]
  end

  let(:base_owner_permissions) do
    %i[
      change_namespace change_visibility_level rename_project remove_project
      archive_project remove_fork_project destroy_merge_request destroy_issue
      set_issue_iid set_issue_created_at set_issue_updated_at set_note_created_at
    ]
  end

  # Used in EE specs
  let(:additional_guest_permissions) { [] }
  let(:additional_reporter_permissions) { [] }
  let(:additional_maintainer_permissions) { [] }
  let(:additional_owner_permissions) { [] }

  let(:guest_permissions) { base_guest_permissions + additional_guest_permissions }
  let(:reporter_permissions) { base_reporter_permissions + additional_reporter_permissions }
  let(:maintainer_permissions) { base_maintainer_permissions + additional_maintainer_permissions }
  let(:owner_permissions) { base_owner_permissions + additional_owner_permissions }

  before do
    project.add_guest(guest)
    project.add_maintainer(maintainer)
    project.add_developer(developer)
    project.add_reporter(reporter)
  end
end
