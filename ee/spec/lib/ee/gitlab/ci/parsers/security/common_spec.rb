# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Parsers::Security::Common do
  describe '#parse!' do
    where(vulnerability_finding_signatures_enabled: [true, false])
    with_them do
      let_it_be(:pipeline) { create(:ci_pipeline) }

      let(:artifact) { build(:ci_job_artifact, :common_security_report) }
      let(:report) { Gitlab::Ci::Reports::Security::Report.new(artifact.file_type, pipeline, 2.weeks.ago) }
      let(:location) { ::Gitlab::Ci::Reports::Security::Locations::DependencyScanning.new(file_path: 'yarn/yarn.lock', package_version: 'v2', package_name: 'saml2') }
      let(:tracking_data) { nil }

      before do
        allow_next_instance_of(described_class) do |parser|
          allow(parser).to receive(:create_location).and_return(location)
          allow(parser).to receive(:tracking_data).and_return(tracking_data)
        end

        artifact.each_blob { |blob| described_class.parse!(blob, report, vulnerability_finding_signatures_enabled) }
      end

      describe 'schema validation' do
        let(:validator_class) { Gitlab::Ci::Parsers::Security::Validators::SchemaValidator }
        let(:parser) { described_class.new('{}', report, vulnerability_finding_signatures_enabled, validate: validate) }

        subject(:parse_report) { parser.parse! }

        before do
          allow(validator_class).to receive(:new).and_call_original
        end

        context 'when the validate flag is set as `false`' do
          let(:validate) { false }

          it 'does not run the validation logic' do
            parse_report

            expect(validator_class).not_to have_received(:new)
          end
        end

        context 'when the validate flag is set as `true`' do
          let(:validate) { true }
          let(:valid?) { false }

          before do
            allow_next_instance_of(validator_class) do |instance|
              allow(instance).to receive(:valid?).and_return(valid?)
              allow(instance).to receive(:errors).and_return(['foo'])
            end

            allow(parser).to receive_messages(create_scanner: true, create_scan: true, collate_remediations: [])
          end

          it 'instantiates the validator with correct params' do
            parse_report

            expect(validator_class).to have_received(:new).with(report.type, {})
          end

          context 'when the report data is not valid according to the schema' do
            it 'adds errors to the report' do
              expect { parse_report }.to change { report.errors }.from([]).to([{ message: 'foo', type: 'Schema' }])
            end

            it 'does not try to create report entities' do
              parse_report

              expect(parser).not_to have_received(:create_scanner)
              expect(parser).not_to have_received(:create_scan)
              expect(parser).not_to have_received(:collate_remediations)
            end
          end

          context 'when the report data is valid according to the schema' do
            let(:valid?) { true }

            it 'does not add errors to the report' do
              expect { parse_report }.not_to change { report.errors }.from([])
            end

            it 'keeps the execution flow as normal' do
              parse_report

              expect(parser).to have_received(:create_scanner)
              expect(parser).to have_received(:create_scan)
              expect(parser).to have_received(:collate_remediations)
            end
          end
        end
      end

      describe 'parsing finding.name' do
        let(:artifact) { build(:ci_job_artifact, :common_security_report_with_blank_names) }

        context 'when message is provided' do
          it 'sets message from the report as a finding name' do
            finding = report.findings.find { |x| x.compare_key == 'CVE-1020' }
            expected_name = Gitlab::Json.parse(finding.raw_metadata)['message']

            expect(finding.name).to eq(expected_name)
          end
        end

        context 'when message is not provided' do
          context 'and name is provided' do
            it 'sets name from the report as a name' do
              finding = report.findings.find { |x| x.compare_key == 'CVE-1030' }
              expected_name = Gitlab::Json.parse(finding.raw_metadata)['name']

              expect(finding.name).to eq(expected_name)
            end
          end

          context 'and name is not provided' do
            context 'when CVE identifier exists' do
              it 'combines identifier with location to create name' do
                finding = report.findings.find { |x| x.compare_key == 'CVE-2017-11429' }
                expect(finding.name).to eq("CVE-2017-11429 in yarn.lock")
              end
            end

            context 'when CWE identifier exists' do
              it 'combines identifier with location to create name' do
                finding = report.findings.find { |x| x.compare_key == 'CWE-2017-11429' }
                expect(finding.name).to eq("CWE-2017-11429 in yarn.lock")
              end
            end

            context 'when neither CVE nor CWE identifier exist' do
              it 'combines identifier with location to create name' do
                finding = report.findings.find { |x| x.compare_key == 'OTHER-2017-11429' }
                expect(finding.name).to eq("other-2017-11429 in yarn.lock")
              end
            end
          end
        end
      end

      describe 'parsing finding.details' do
        context 'when details are provided' do
          it 'sets details from the report' do
            finding = report.findings.find { |x| x.compare_key == 'CVE-1020' }
            expected_details = Gitlab::Json.parse(finding.raw_metadata)['details']

            expect(finding.details).to eq(expected_details)
          end
        end

        context 'when details are not provided' do
          it 'sets empty hash' do
            finding = report.findings.find { |x| x.compare_key == 'CVE-1030' }
            expect(finding.details).to eq({})
          end
        end
      end

      describe 'parsing remediations' do
        let(:expected_remediation) { create(:ci_reports_security_remediation, diff: '') }

        it 'finds remediation with same cve' do
          finding = report.findings.find { |x| x.compare_key == "CVE-1020" }
          remediation = { 'fixes' => [{ 'cve' => 'CVE-1020' }], 'summary' => '', 'diff' => '' }

          expect(Gitlab::Json.parse(finding.raw_metadata).dig('remediations').first).to include remediation
          expect(finding.remediations.first.checksum).to eq(expected_remediation.checksum)
        end

        it 'finds remediation with same id' do
          finding = report.findings.find { |x| x.compare_key == "CVE-1030" }
          remediation = { 'fixes' => [{ 'cve' => 'CVE', 'id' => 'bb2fbeb1b71ea360ce3f86f001d4e84823c3ffe1a1f7d41ba7466b14cfa953d3' }], 'summary' => '', 'diff' => '' }

          expect(Gitlab::Json.parse(finding.raw_metadata).dig('remediations').first).to include remediation
          expect(finding.remediations.first.checksum).to eq(expected_remediation.checksum)
        end

        it 'does not find remediation with different id' do
          fix_with_id = {
            "fixes": [
              {
               "id": "2134",
               "cve": "CVE-1"
              }
            ],
            "summary": "",
            "diff": ""
          }

          report.findings.map do |finding|
            expect(Gitlab::Json.parse(finding.raw_metadata).dig('remediations')).not_to include(fix_with_id)
          end
        end
      end

      describe 'top-level scanner' do
        it 'is the primary scanner' do
          expect(report.primary_scanner.external_id).to eq('gemnasium')
          expect(report.primary_scanner.name).to eq('Gemnasium')
          expect(report.primary_scanner.vendor).to eq('GitLab')
          expect(report.primary_scanner.version).to eq('2.18.0')
        end

        it 'returns nil report has no scanner' do
          empty_report = Gitlab::Ci::Reports::Security::Report.new(artifact.file_type, pipeline, 2.weeks.ago)
          described_class.parse!({}.to_json, empty_report)

          expect(empty_report.primary_scanner).to be_nil
        end
      end

      describe 'parsing scanners' do
        subject(:scanner) { report.findings.first.scanner }

        context 'when vendor is not missing in scanner' do
          it 'returns scanner with parsed vendor value' do
            expect(scanner.vendor).to eq('GitLab')
          end
        end
      end

      describe 'parsing scan' do
        it 'returns scan object for each finding' do
          scans = report.findings.map(&:scan)

          expect(scans.map(&:status).all?('success')).to be(true)
          expect(scans.map(&:type).all?('dependency_scanning')).to be(true)
          expect(scans.map(&:start_time).all?('placeholder-value')).to be(true)
          expect(scans.map(&:end_time).all?('placeholder-value')).to be(true)
          expect(scans.size).to eq(3)
          expect(scans.first).to be_a(::Gitlab::Ci::Reports::Security::Scan)
        end

        it 'returns nil when scan is not a hash' do
          empty_report = Gitlab::Ci::Reports::Security::Report.new(artifact.file_type, pipeline, 2.weeks.ago)
          described_class.parse!({}.to_json, empty_report)

          expect(empty_report.scan).to be(nil)
        end
      end

      describe 'parsing schema version' do
        it 'parses the version' do
          expect(report.version).to eq('14.0.2')
        end

        it 'returns nil when there is no version' do
          empty_report = Gitlab::Ci::Reports::Security::Report.new(artifact.file_type, pipeline, 2.weeks.ago)
          described_class.parse!({}.to_json, empty_report)

          expect(empty_report.version).to be_nil
        end
      end

      describe 'parsing analyzer' do
        it 'associates analyzer with report' do
          expect(report.analyzer.id).to eq('common-analyzer')
          expect(report.analyzer.name).to eq('Common Analyzer')
          expect(report.analyzer.version).to eq('2.0.1')
          expect(report.analyzer.vendor).to eq('Common')
        end

        it 'returns nil when analyzer data is not available' do
          empty_report = Gitlab::Ci::Reports::Security::Report.new(artifact.file_type, pipeline, 2.weeks.ago)
          described_class.parse!({}.to_json, empty_report)

          expect(empty_report.analyzer).to be_nil
        end
      end

      describe 'parsing links' do
        it 'returns links object for each finding', :aggregate_failures do
          links = report.findings.flat_map(&:links)

          expect(links.map(&:url)).to match_array(['https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-1020', 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-1030'])
          expect(links.map(&:name)).to match_array([nil, 'CVE-1030'])
          expect(links.size).to eq(2)
          expect(links.first).to be_a(::Gitlab::Ci::Reports::Security::Link)
        end
      end

      describe 'setting the uuid' do
        let(:location) { build(:ci_reports_security_locations_sast) }

        let(:finding_uuids) { report.findings.map(&:uuid) }
        let(:uuid_1) do
          Security::VulnerabilityUUID.generate(
            report_type: "sast",
            primary_identifier_fingerprint: report.findings[0].identifiers.first.fingerprint,
            location_fingerprint: location.fingerprint,
            project_id: pipeline.project_id
          )
        end

        let(:uuid_2) do
          Security::VulnerabilityUUID.generate(
            report_type: "sast",
            primary_identifier_fingerprint: report.findings[1].identifiers.first.fingerprint,
            location_fingerprint: location.fingerprint,
            project_id: pipeline.project_id
          )
        end

        let(:expected_uuids) { [uuid_1, uuid_2, nil] }

        it 'sets the UUIDv5 for findings', :aggregate_failures do
          allow_next_instance_of(Gitlab::Ci::Reports::Security::Report) do |report|
            allow(report).to receive(:type).and_return('sast')

            expect(finding_uuids).to match_array(expected_uuids)
          end
        end
      end

      describe 'parsing tracking' do
        let(:tracking_data) do
          {
            'type' => 'source',
            'items' => [
              'signatures' => [
                { 'algorithm' => 'hash', 'value' => 'hash_value' },
                { 'algorithm' => 'location', 'value' => 'location_value' },
                { 'algorithm' => 'scope_offset', 'value' => 'scope_offset_value' }
              ]
            ]
          }
        end

        context 'with valid tracking information' do
          it 'creates signatures for each algorithm' do
            finding = report.findings.first
            expect(finding.signatures.size).to eq(3)
            expect(finding.signatures.map(&:algorithm_type).to_set).to eq(Set['hash', 'location', 'scope_offset'])
          end
        end

        context 'with invalid tracking information' do
          let(:tracking_data) do
            {
              'type' => 'source',
              'items' => [
                'signatures' => [
                  { 'algorithm' => 'hash', 'value' => 'hash_value' },
                  { 'algorithm' => 'location', 'value' => 'location_value' },
                  { 'algorithm' => 'INVALID', 'value' => 'scope_offset_value' }
                ]
              ]
            }
          end

          it 'ignores invalid algorithm types' do
            finding = report.findings.first
            expect(finding.signatures.size).to eq(2)
            expect(finding.signatures.map(&:algorithm_type).to_set).to eq(Set['hash', 'location'])
          end
        end

        context 'with valid tracking information' do
          it 'creates signatures for each signature algorithm' do
            finding = report.findings.first
            expect(finding.signatures.size).to eq(3)
            expect(finding.signatures.map(&:algorithm_type)).to eq(%w[hash location scope_offset])

            signatures = finding.signatures.index_by(&:algorithm_type)
            expected_values = tracking_data['items'][0]['signatures'].index_by { |x| x['algorithm'] }
            expect(signatures['hash'].signature_value).to eq(expected_values['hash']['value'])
            expect(signatures['location'].signature_value).to eq(expected_values['location']['value'])
            expect(signatures['scope_offset'].signature_value).to eq(expected_values['scope_offset']['value'])
          end

          it 'sets the uuid according to the higest priority signature' do
            finding = report.findings.first
            highest_signature = finding.signatures.max_by(&:priority)

            identifiers = if vulnerability_finding_signatures_enabled
                            "#{finding.report_type}-#{finding.primary_identifier.fingerprint}-#{highest_signature.signature_hex}-#{report.project_id}"
                          else
                            "#{finding.report_type}-#{finding.primary_identifier.fingerprint}-#{finding.location.fingerprint}-#{report.project_id}"
                          end

            expect(finding.uuid).to eq(Gitlab::UUID.v5(identifiers))
          end
        end
      end
    end
  end
end
