RSpec.describe ProcedureHelper, type: :helper do
  let(:procedure) { create(:procedure) }

  describe '#dossiers_deletion_warning' do
    subject { dossiers_deletion_warning(procedure) }

    context 'with 1 submitted dossier' do
      before do
        dossier_1 = create(:dossier, :en_construction, procedure: procedure)
      end

      it { is_expected.to eq('1 dossier est rattaché à cette procédure, la suppression de cette procédure entrainera également leur suppression.') }
    end

    context 'with 2 submitted dossiers' do
      before do
        dossier_1 = create(:dossier, :en_construction, procedure: procedure)
        dossier_2 = create(:dossier, :en_instruction, procedure: procedure)
      end

      it { is_expected.to eq('2 dossiers sont rattachés à cette procédure, la suppression de cette procédure entrainera également leur suppression.') }
    end

    context 'with 1 brouillon dossier' do
      before do
        dossier_1 = create(:dossier, procedure: procedure)
      end

      it { is_expected.to eq('1 brouillon est rattaché à cette procédure, la suppression de cette procédure entrainera également leur suppression.') }
    end

    context 'with 2 brouillons dossiers' do
      before do
        dossier_1 = create(:dossier, procedure: procedure)
        dossier_2 = create(:dossier, procedure: procedure)
      end

      it { is_expected.to eq('2 brouillons sont rattachés à cette procédure, la suppression de cette procédure entrainera également leur suppression.') }
    end

    context 'with 2 submitted dossiers and 1 brouillon dossier' do
      before do
        dossier_1 = create(:dossier, :en_instruction, procedure: procedure)
        dossier_2 = create(:dossier, :en_instruction, procedure: procedure)
        dossier_3 = create(:dossier, procedure: procedure)
      end

      it { is_expected.to eq('2 dossiers et 1 brouillon sont rattachés à cette procédure, la suppression de cette procédure entrainera également leur suppression.') }
    end
  end
end
