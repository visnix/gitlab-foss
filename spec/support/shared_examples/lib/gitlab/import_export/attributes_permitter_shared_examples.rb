# frozen_string_literal: true
RSpec.shared_examples 'a permitted attribute' do |relation_sym, permitted_attributes|
  let(:prohibited_attributes) { %i[remote_url my_attributes my_ids token my_id test] }

  let(:import_export_config) { Gitlab::ImportExport::Config.new.to_h }
  let(:project_relation_factory) { Gitlab::ImportExport::Project::RelationFactory }

  let(:relation_hash) { (permitted_attributes + prohibited_attributes).map(&:to_s).zip([]).to_h }
  let(:relation_name) { project_relation_factory.overrides[relation_sym]&.to_sym || relation_sym }
  let(:relation_class) { project_relation_factory.relation_class(relation_name) }
  let(:excluded_keys) { import_export_config.dig(:excluded_keys, relation_sym) || [] }

  let(:cleaned_hash) do
    Gitlab::ImportExport::AttributeCleaner.new(
      relation_hash: relation_hash,
      relation_class: relation_class,
      excluded_keys: excluded_keys
    ).clean
  end

  let(:permitted_hash) { subject.permit(relation_sym, relation_hash) }

  if described_class.new.permitted_attributes_defined?(relation_sym)
    it 'contains only attributes that are defined as permitted in the import/export config' do
      expect(permitted_hash.keys).to contain_exactly(*permitted_attributes.map(&:to_s))
    end

    it 'does not contain attributes that would be cleaned with AttributeCleaner' do
      expect(cleaned_hash.keys).to include(*permitted_hash.keys)
    end

    it 'does not contain prohibited attributes that are not related to given relation' do
      expect(permitted_hash.keys).not_to include(*prohibited_attributes.map(&:to_s))
    end
  else
    it 'is disabled' do
      expect(subject).not_to be_permitted_attributes_defined(relation_sym)
    end
  end
end
