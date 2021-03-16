# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Operations dropdown navbar EE' do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  before do
    stub_feature_flags(combined_menu: false)

    project.add_maintainer(user)
    sign_in(user)

    stub_licensed_features(operations_dashboard: true)

    visit project_issues_path(project)
  end

  it 'has an `Operations` link' do
    expect(page).to have_link('Operations', href: operations_path)
  end

  it 'has an `Environments` link' do
    expect(page).to have_link('Environments', href: operations_environments_path)
  end
end
