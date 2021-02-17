RSpec.describe ExpertsProcedure, type: :model do
  describe '#invited_expert_emails' do
    let!(:procedure) { create(:procedure, :published) }
    let(:expert) { create(:expert) }
    let(:expert2) { create(:expert) }
    let(:expert3) { create(:expert) }
    let(:experts_procedure) { ExpertsProcedure.create(expert: expert, procedure: procedure) }
    let(:experts_procedure2) { ExpertsProcedure.create(expert: expert2, procedure: procedure) }
    let(:experts_procedure3) { ExpertsProcedure.create(expert: expert3, procedure: procedure) }
    subject { ExpertsProcedure.invited_expert_emails(procedure) }

    context 'when there is one dossier' do
      let!(:dossier) { create(:dossier, procedure: procedure) }

      context 'when a procedure has one avis and known instructeur' do
        let!(:avis) { create(:avis, dossier: dossier, instructeur: create(:instructeur, email: expert.email), experts_procedure: experts_procedure) }

        it { is_expected.to eq([expert.email]) }
      end

      context 'when a dossier has 2 avis from the same expert' do
        let!(:avis) { create(:avis, dossier: dossier, experts_procedure: experts_procedure) }
        let!(:avis2) { create(:avis, dossier: dossier, experts_procedure: experts_procedure) }

        it { is_expected.to eq([expert.email]) }
      end
    end

    context 'when there are two dossiers' do
      let!(:dossier) { create(:dossier, procedure: procedure) }
      let!(:dossier2) { create(:dossier, procedure: procedure) }

      context 'and each one has an avis from 3 different experts' do
        let!(:avis) { create(:avis, dossier: dossier, experts_procedure: experts_procedure) }
        let!(:avis2) { create(:avis, dossier: dossier2, experts_procedure: experts_procedure2) }
        let!(:avis3) { create(:avis, dossier: dossier2, experts_procedure: experts_procedure3) }

        it { is_expected.to eq([expert.email, expert2.email, expert3.email].sort) }
      end
    end
  end
end
