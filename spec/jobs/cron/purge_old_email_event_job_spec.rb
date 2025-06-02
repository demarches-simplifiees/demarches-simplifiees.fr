# frozen_string_literal: true

RSpec.describe Cron::PurgeOldEmailEventJob, type: :job do
  describe 'perform' do
    subject { Cron::PurgeOldEmailEventJob.perform_now }
    let(:older_than_retention_duration) { create(:email_event, :dolist, created_at: Time.zone.now - (EmailEvent::RETENTION_DURATION + 1.day)) }
    let(:more_recent_than_retention_duration) { create(:email_event, :dolist, created_at: Time.zone.now - (EmailEvent::RETENTION_DURATION - 1.day)) }
    before do
      older_than_retention_duration
      more_recent_than_retention_duration
    end

    it { expect { subject }.to change { EmailEvent.count }.by(-1) }
    it { expect { subject }.to change { EmailEvent.exists?(id: older_than_retention_duration.id) }.from(true).to(false) }
  end
end
