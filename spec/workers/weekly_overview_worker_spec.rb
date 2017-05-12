require 'rails_helper'

RSpec.describe WeeklyOverviewWorker, type: :worker do
  describe 'perform' do
    let!(:gestionnaire) { create(:gestionnaire) }
    let(:overview) { double('overview') }
    let(:mailer_double) { double('mailer', deliver_now: true) }

    context 'with one gestionnaire with one overview' do
      before :each do
        expect_any_instance_of(Gestionnaire).to receive(:last_week_overview).and_return(overview)
        allow(GestionnaireMailer).to receive(:last_week_overview).and_return(mailer_double)
        WeeklyOverviewWorker.new.perform
      end

      it { expect(GestionnaireMailer).to have_received(:last_week_overview).with(gestionnaire, overview) }
      it { expect(mailer_double).to have_received(:deliver_now) }
    end

    context 'with one gestionnaire with no overviews' do
      before :each do
        expect_any_instance_of(Gestionnaire).to receive(:last_week_overview).and_return(nil)
        allow(GestionnaireMailer).to receive(:last_week_overview)
        WeeklyOverviewWorker.new.perform
      end

      it { expect(GestionnaireMailer).not_to have_received(:last_week_overview) }
    end
  end
end
