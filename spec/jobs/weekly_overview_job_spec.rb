require 'rails_helper'

RSpec.describe WeeklyOverviewJob, type: :job do
  describe 'perform' do
    let!(:gestionnaire) { create(:gestionnaire) }
    let(:overview) { double('overview') }
    let(:mailer_double) { double('mailer', deliver_later: true) }

    context 'if the feature is enabled' do
      before { allow(Features).to receive(:weekly_overview).and_return(true) }

      context 'with one gestionnaire with one overview' do
        before :each do
          expect_any_instance_of(Gestionnaire).to receive(:last_week_overview).and_return(overview)
          allow(GestionnaireMailer).to receive(:last_week_overview).and_return(mailer_double)
          WeeklyOverviewJob.new.perform
        end

        it { expect(GestionnaireMailer).to have_received(:last_week_overview).with(gestionnaire) }
        it { expect(mailer_double).to have_received(:deliver_later) }
      end

      context 'with one gestionnaire with no overviews' do
        before :each do
          expect_any_instance_of(Gestionnaire).to receive(:last_week_overview).and_return(nil)
          allow(GestionnaireMailer).to receive(:last_week_overview)
          WeeklyOverviewJob.new.perform
        end

        it { expect(GestionnaireMailer).not_to have_received(:last_week_overview) }
      end
    end

    context 'if the feature is disabled' do
      before { allow(Features).to receive(:weekly_overview).and_return(false) }
      before :each do
        allow(Gestionnaire).to receive(:all)
        WeeklyOverviewJob.new.perform
      end

      it { expect(Gestionnaire).not_to receive(:all) }
    end
  end
end
