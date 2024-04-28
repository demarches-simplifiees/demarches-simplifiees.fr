# frozen_string_literal: true

RSpec.describe Cron::WeeklyOverviewJob, type: :job do
  describe 'perform' do
    let!(:instructeur) { create(:instructeur) }
    let(:overview) { double('overview') }

    context 'if the feature is enabled' do
      before do
        Rails.application.config.ds_weekly_overview = true
      end
      after do
        Rails.application.config.ds_weekly_overview = false
      end

      subject(:run_job) { Cron::WeeklyOverviewJob.new.perform }
      # See also spec/mailers/instructeur_mailer_spec.rb

      context 'with one instructeur with one overview' do
        let(:mailer_double) { double('mailer', deliver_later: true) }
        before do
          allow(InstructeurMailer).to receive(:last_week_overview).and_return(mailer_double)
          run_job
        end

        it do
          expect(InstructeurMailer).to have_received(:last_week_overview).with(instructeur)
          expect(mailer_double).to have_received(:deliver_later).at_least(1).times
        end
      end

      context 'with one instructeur with no overviews' do
        before do
          allow(InstructeurMailer).to receive(:last_week_overview).and_return(nil)
          run_job
        end

        it { expect(InstructeurMailer).to have_received(:last_week_overview).with(instructeur) }
        it { expect { run_job }.not_to raise_error }
      end
    end

    context 'if the feature is disabled' do
      before do
        allow(Instructeur).to receive(:find_each)
        Cron::WeeklyOverviewJob.new.perform
      end

      it { expect(Instructeur).not_to receive(:find_each) }
    end
  end
end
