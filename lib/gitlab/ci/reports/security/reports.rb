# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Security
        class Reports
          attr_reader :reports, :pipeline

          delegate :each, :empty?, to: :reports

          def initialize(pipeline)
            @reports = {}
            @pipeline = pipeline
          end

          def get_report(report_type, report_artifact)
            reports[report_type] ||= Report.new(report_type, pipeline, report_artifact.created_at)
          end

          def findings
            reports.values.flat_map(&:findings)
          end

          def violates_default_policy_against?(target_reports, vulnerabilities_allowed, severity_levels, vulnerability_states)
            unsafe_findings_count(target_reports, severity_levels, vulnerability_states) > vulnerabilities_allowed
          end

          def unsafe_findings_uuids(severity_levels)
            findings.select { |finding| finding.unsafe?(severity_levels) }.map(&:uuid)
          end

          private

          def unsafe_findings_count(target_reports, severity_levels, vulnerability_states)
            new_uuids = unsafe_findings_uuids(severity_levels) - target_reports&.unsafe_findings_uuids(severity_levels).to_a
            new_uuids.count
          end
        end
      end
    end
  end
end

Gitlab::Ci::Reports::Security::Reports.prepend_mod_with('Gitlab::Ci::Reports::Security::Reports')
