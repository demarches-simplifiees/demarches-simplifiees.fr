RSpec.describe Cron::PurgeManagerAdministrateurSessionsJob, type: :job do
  describe 'perform' do
    let(:administrateur) { create(:administrateur) }
    let(:procedure) { create(:procedure) }

    subject { Cron::PurgeManagerAdministrateurSessionsJob.perform_now }

    context "with an inactive administrateur" do
      before do
        AdministrateursProcedure.create(procedure: procedure, administrateur: administrateur, manager: true)
        expect(AdministrateursProcedure.where(manager: true).count).to eq(1)
        expect(AdministrateursProcedure.count).to eq(2)
        subject
      end

      it {
        expect(AdministrateursProcedure.where(manager: true).count).to eq(0)
        expect(AdministrateursProcedure.count).to eq(1)
      }
    end
  end
end
