# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::AgentAuthorizationsFinder do
  describe '#execute' do
    let_it_be(:top_level_group) { create(:group) }
    let_it_be(:subgroup1) { create(:group, parent: top_level_group) }
    let_it_be(:subgroup2) { create(:group, parent: subgroup1) }
    let_it_be(:bottom_level_group) { create(:group, parent: subgroup2) }

    let_it_be(:agent_configuration_project) { create(:project, namespace: subgroup1) }
    let_it_be(:requesting_project, reload: true) { create(:project, namespace: bottom_level_group) }

    let_it_be(:staging_agent) { create(:cluster_agent, project: agent_configuration_project) }
    let_it_be(:production_agent) { create(:cluster_agent, project: agent_configuration_project) }

    let(:feature_available) { true }

    subject { described_class.new(requesting_project).execute }

    before do
      stub_licensed_features(cluster_agents: feature_available)
    end

    context 'feature is not available' do
      let(:feature_available) { false }

      it { is_expected.to be_empty }
    end

    describe 'implicit authorizations' do
      let!(:associated_agent) { create(:cluster_agent, project: requesting_project) }

      it 'returns authorazations for agents directly associated with the project' do
        expect(subject.count).to eq(1)

        authorazation = subject.first
        expect(authorazation).to be_a(Clusters::Agents::ImplicitAuthorization)
        expect(authorazation.agent).to eq(associated_agent)
      end
    end

    describe 'authorized groups' do
      context 'agent configuration project is outside the requesting project hierarchy' do
        let(:unrelated_agent) { create(:cluster_agent) }

        before do
          create(:agent_group_authorization, agent: unrelated_agent, group: top_level_group)
        end

        it { is_expected.to be_empty }
      end

      context 'multiple agents are authorized for the same group' do
        let!(:staging_auth) { create(:agent_group_authorization, agent: staging_agent, group: bottom_level_group) }
        let!(:production_auth) { create(:agent_group_authorization, agent: production_agent, group: bottom_level_group) }

        it 'returns authorizations for all agents' do
          expect(subject).to contain_exactly(staging_auth, production_auth)
        end
      end

      context 'a single agent is authorized to more than one matching group' do
        let!(:bottom_level_auth) { create(:agent_group_authorization, agent: production_agent, group: bottom_level_group) }
        let!(:top_level_auth) { create(:agent_group_authorization, agent: production_agent, group: top_level_group) }

        it 'picks the authorization for the closest group to the requesting project' do
          expect(subject).to contain_exactly(bottom_level_auth)
        end
      end
    end
  end
end
