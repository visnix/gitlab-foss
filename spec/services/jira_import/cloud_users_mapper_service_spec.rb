# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraImport::CloudUsersMapperService do
  let(:start_at) { 7 }
  let(:url) { "/rest/api/2/users?maxResults=50&startAt=#{start_at}" }

  let_it_be(:user_1) { create(:user, username: 'randomuser', name: 'USER-name1', email: 'uji@example.com') }
  let_it_be(:user_2) { create(:user, username: 'username2') }
  let_it_be(:user_5) { create(:user, username: 'username5') }
  let_it_be(:user_4) { create(:user, email: 'user4@example.com') }
  let_it_be(:user_6) { create(:user, email: 'user6@example.com') }
  let_it_be(:user_7) { create(:user, username: 'username7') }
  let_it_be(:user_8) do
    create(:user).tap { |user| create(:email, user: user, email: 'user8_email@example.com') }
  end

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group)        { create(:group) }
  let_it_be(:project)      { create(:project, group: group) }

  let(:jira_users) do
    [
      { 'accountId' => 'abcd', 'displayName' => 'User-Name1' }, # matched by name
      { 'accountId' => 'efg', 'displayName' => 'username2' }, # matcher by username
      { 'accountId' => 'hij' }, # no match
      { 'accountId' => '123', 'displayName' => 'user4', 'emailAddress' => 'user4@example.com' }, # matched by email
      { 'accountId' => '456', 'displayName' => 'username5foo', 'emailAddress' => 'user5@example.com' }, # no match
      { 'accountId' => '789', 'displayName' => 'user6', 'emailAddress' => 'user6@example.com' }, # matched by email, no project member
      { 'accountId' => 'xyz', 'displayName' => 'username7', 'emailAddress' => 'user7@example.com' }, # matched by username, no project member
      { 'accountId' => 'vhk', 'displayName' => 'user8', 'emailAddress' => 'user8_email@example.com' }, # matched by secondary email
      { 'accountId' => 'uji', 'displayName' => 'user9', 'emailAddress' => 'uji@example.com' } # matched by email, same as user_1
    ]
  end

  describe '#execute' do
    before do
      project.add_developer(current_user)
      project.add_developer(user_1)
      project.add_developer(user_2)
      group.add_developer(user_4)
      group.add_guest(user_8)
    end

    it_behaves_like 'mapping jira users'
  end
end
