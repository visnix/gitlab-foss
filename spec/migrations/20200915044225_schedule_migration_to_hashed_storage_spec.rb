# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ScheduleMigrationToHashedStorage, :sidekiq do
  describe '#up' do
    it 'schedules background migration job' do
      Sidekiq::Testing.fake! do
        expect { migrate! }.to change { BackgroundMigrationWorker.jobs.size }.by(1)
      end
    end
  end
end
