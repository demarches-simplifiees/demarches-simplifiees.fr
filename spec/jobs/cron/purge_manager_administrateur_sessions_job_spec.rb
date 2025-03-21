RSpec.describe Cron::PurgeManagerAdministrateurSessionsJob, type: :job do
  describe 'perform' do
    let(:administrateur) { create(:administrateur) }
    let(:procedure) { create(:procedure) }

    subject { Cron::PurgeManagerAdministrateurSessionsJob.perform_now }

    context "with an inactive administrateur" do
      before do
        AdministrateursProcedure.create(procedure: procedure, administrateur: administrateur, manager: true)
      end

      it {
        expect(AdministrateursProcedure.where(procedure:, manager: true).count).to eq(1)
        expect(AdministrateursProcedure.where(procedure:).count).to eq(2)
        subject
        expect(AdministrateursProcedure.where(procedure:, manager: true).count).to eq(0)
        expect(AdministrateursProcedure.where(procedure:).count).to eq(1)
      }
    end
  end
end
