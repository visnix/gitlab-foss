# frozen_string_literal: true

require 'spec_helper'

describe 'view audit events' do
  describe 'GET /groups/:group/-/audit_events' do
    let_it_be(:group) { create(:group) }
    let_it_be(:user) { create(:user) }
    let_it_be(:audit_event) { create(:group_audit_event, entity_id: group.id) }

    before do
      stub_licensed_features(audit_events: true)

      group.add_owner(user)
      login_as(user)
    end

    it 'returns 200' do
      send_request

      expect(response.status).to eq(200)
    end

    it 'avoids N+1 DB queries', :request_store do
      # warm up cache so these initial queries would not leak in our QueryRecorder
      send_request

      control = ActiveRecord::QueryRecorder.new(skip_cached: false) { send_request }

      create_list(:group_audit_event, 2, entity_id: group.id)

      expect do
        send_request
      end.not_to exceed_all_query_limit(control)
    end

    def send_request
      get group_audit_events_path(group)
    end
  end
end
