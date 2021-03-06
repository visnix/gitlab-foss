# frozen_string_literal: true

module LooseForeignKeys
  class BatchCleanerService
    def initialize(parent_klass:, deleted_parent_records:, modification_tracker: LooseForeignKeys::ModificationTracker.new, models_by_table_name:)
      @parent_klass = parent_klass
      @deleted_parent_records = deleted_parent_records
      @modification_tracker = modification_tracker
      @models_by_table_name = models_by_table_name
    end

    def execute
      parent_klass.loose_foreign_key_definitions.each do |foreign_key_definition|
        run_cleaner_service(foreign_key_definition, with_skip_locked: true)
        break if modification_tracker.over_limit?

        run_cleaner_service(foreign_key_definition, with_skip_locked: false)
        break if modification_tracker.over_limit?
      end

      return if modification_tracker.over_limit?

      # At this point, all associations are cleaned up, we can update the status of the parent records
      LooseForeignKeys::DeletedRecord
        .mark_records_processed_for_table_between(deleted_parent_records.first.fully_qualified_table_name, deleted_parent_records.first, deleted_parent_records.last)
    end

    private

    attr_reader :parent_klass, :deleted_parent_records, :modification_tracker, :models_by_table_name

    def record_result(cleaner, result)
      if cleaner.async_delete?
        modification_tracker.add_deletions(result[:table], result[:affected_rows])
      elsif cleaner.async_nullify?
        modification_tracker.add_updates(result[:table], result[:affected_rows])
      end
    end

    def run_cleaner_service(foreign_key_definition, with_skip_locked:)
      cleaner = CleanerService.new(
        model: models_by_table_name.fetch(foreign_key_definition.to_table),
        foreign_key_definition: foreign_key_definition,
        deleted_parent_records: deleted_parent_records,
        with_skip_locked: with_skip_locked
      )

      loop do
        result = cleaner.execute
        record_result(cleaner, result)

        break if modification_tracker.over_limit? || result[:affected_rows] == 0
      end
    end
  end
end
