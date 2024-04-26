RSpec.describe RecoveryService, type: :service do
  describe '.recoverable_procedures' do
    subject { described_class.recoverable_procedures(previous_user:, siret:) }

    context 'when the previous_user is nil' do
      let(:previous_user) { nil }
      let(:siret) { '123' }

      it 'returns []' do
        expect(subject).to eq([])
      end
    end

    context 'when the previous_user has some dossiers' do
      let(:previous_user) { create(:user) }

      let(:procedure_1) { create(:procedure) }
      let(:siret) { '123' }

      let(:procedure_2) { create(:procedure) }
      let(:another_siret) { 'another_123' }

      before do
        3.times do
          create(:dossier, procedure: procedure_1,
                 etablissement: create(:etablissement, siret:),
                 user: previous_user)
        end

        create(:dossier, procedure: procedure_2,
               etablissement: create(:etablissement, siret: another_siret),
               user: previous_user)
      end

      it 'returns the procedures with their count' do
        expect(subject).to eq([{ procedure_id: procedure_1.id, libelle: procedure_1.libelle, count: 3 }])
      end
    end
  end

  describe '.recover_procedure!' do
    subject { described_class.recover_procedure!(previous_user:, next_user:, siret:, procedure_ids:) }

    context 'when the previous_user has some dossiers' do
      let!(:previous_user) { create(:user) }
      let!(:next_user) { create(:user) }

      let!(:procedure_1) { create(:procedure) }
      let!(:siret) { '123' }

      let!(:procedure_2) { create(:procedure) }
      let!(:another_siret) { 'another_123' }

      let!(:dossiers_to_recover) do
        3.times do
          create(:dossier, procedure: procedure_1,
                 etablissement: create(:etablissement, siret:),
                 user: previous_user)
        end
      end

      let!(:dossiers_not_to_recover) do
        create(:dossier, procedure: procedure_2,
               etablissement: create(:etablissement, siret: another_siret),
               user: previous_user)
      end

      let(:procedure_ids) { [procedure_1.id] }

      it 'moves the files to the next user' do
        subject
        expect(next_user.dossiers.count).to eq(3)

        dossier_transfer_log = next_user.dossiers.first.transfer_logs.first
        expect(dossier_transfer_log.from).to eq(previous_user.email)
        expect(dossier_transfer_log.to).to eq(next_user.email)
      end
    end
  end
end
