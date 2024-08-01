# frozen_string_literal: true

RSpec.describe Cron::Datagouv::ExportAndPublishDemarchesPubliquesJob, type: :job do
  describe '#schedulable?' do
    it 'is schedulable by default' do
      expect(Cron::CronJob.schedulable?).to be_truthy
    end
  end
end
