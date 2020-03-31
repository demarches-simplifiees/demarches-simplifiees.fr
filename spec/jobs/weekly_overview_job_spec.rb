RSpec.describe WeeklyOverviewJob, type: :job do
  describe 'perform' do
    let!(:instructeur) { create(:instructeur) }
    let(:overview) { double('overview') }
    let(:mailer_double) { double('mailer', deliver_later: true) }

    context 'if the feature is enabled' do
      before do
        Rails.application.config.ds_weekly_overview = true
      end
      after do
        Rails.application.config.ds_weekly_overview = false
      end

      context 'with one instructeur with one overview' do
        before do
          expect_any_instance_of(Instructeur).to receive(:last_week_overview).and_return(overview)
          allow(InstructeurMailer).to receive(:last_week_overview).and_return(mailer_double)
          WeeklyOverviewJob.new.perform
        end

        it { expect(InstructeurMailer).to have_received(:last_week_overview).with(instructeur) }
        it { expect(mailer_double).to have_received(:deliver_later) }
      end

      context 'with one instructeur with no overviews' do
        before do
          expect_any_instance_of(Instructeur).to receive(:last_week_overview).and_return(nil)
          allow(InstructeurMailer).to receive(:last_week_overview)
          WeeklyOverviewJob.new.perform
        end

        it { expect(InstructeurMailer).not_to have_received(:last_week_overview) }
      end
    end

    context 'if the feature is disabled' do
      before do
        allow(Instructeur).to receive(:all)
        WeeklyOverviewJob.new.perform
      end

      it { expect(Instructeur).not_to receive(:all) }
    end
  end
end
