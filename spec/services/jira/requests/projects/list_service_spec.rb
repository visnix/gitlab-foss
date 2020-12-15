# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Jira::Requests::Projects::ListService do
  include AfterNextHelpers

  let(:jira_service) { create(:jira_service) }
  let(:params) { {} }

  describe '#execute' do
    let(:service) { described_class.new(jira_service, params) }

    subject { service.execute }

    context 'without jira_service' do
      before do
        jira_service.update!(active: false)
      end

      it 'returns an error response' do
        expect(subject.error?).to be_truthy
        expect(subject.message).to eq('Jira service not configured.')
      end
    end

    context 'when jira_service is nil' do
      let(:jira_service) { nil }

      it 'returns an error response' do
        expect(subject.error?).to be_truthy
        expect(subject.message).to eq('Jira service not configured.')
      end
    end

    context 'with jira_service' do
      context 'when validations and params are ok' do
        let(:response_headers) { { 'content-type' => 'application/json' } }
        let(:response_body) { [].to_json }
        let(:expected_url_pattern) { /.*jira.example.com\/rest\/api\/2\/project/ }

        before do
          stub_request(:get, expected_url_pattern).to_return(status: 200, body: response_body, headers: response_headers)
        end

        context 'when the request to Jira returns an error' do
          before do
            expect_next(JIRA::Client).to receive(:get).and_raise(Timeout::Error)
          end

          it 'returns an error response' do
            expect(Gitlab::ProjectServiceLogger).to receive(:error).with(
              hash_including(
                error: hash_including(:exception_class, :exception_message, :exception_backtrace)))
              .and_call_original
            expect(subject.error?).to be_truthy
            expect(subject.message).to eq('Jira request error: Timeout::Error')
          end
        end

        context 'when jira runs on a subpath' do
          let(:jira_service) { create(:jira_service, url: 'http://jira.example.com/jira') }
          let(:expected_url_pattern) { /.*jira.example.com\/jira\/rest\/api\/2\/project/ }

          it 'takes the subpath into account' do
            expect(subject.success?).to be_truthy
          end
        end

        context 'when the request does not return any values' do
          let(:response_body) { [].to_json }

          it 'returns a paylod with no projects returned' do
            payload = subject.payload

            expect(subject.success?).to be_truthy
            expect(payload[:projects]).to be_empty
            expect(payload[:is_last]).to be_truthy
          end
        end

        context 'when the request returns values' do
          let(:response_body) { [{ 'key' => 'pr1', 'name' => 'First Project' }, { 'key' => 'pr2', 'name' => 'Second Project' }].to_json }

          it 'returns a paylod with Jira projects' do
            payload = subject.payload

            expect(subject.success?).to be_truthy
            expect(payload[:projects].map(&:key)).to eq(%w(pr1 pr2))
            expect(payload[:is_last]).to be_truthy
          end

          context 'when filtering projects by name' do
            let(:params) { { query: 'first' } }

            it 'returns a paylod with Jira procjets' do
              payload = subject.payload

              expect(subject.success?).to be_truthy
              expect(payload[:projects].map(&:key)).to eq(%w(pr1))
              expect(payload[:is_last]).to be_truthy
            end
          end
        end
      end
    end
  end
end
