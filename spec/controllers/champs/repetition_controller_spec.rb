# frozen_string_literal: true

describe Champs::RepetitionController, type: :controller do
  describe '#remove' do
    let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :repetition, mandatory: true, children: [{ libelle: 'Nom' }, { type: :integer_number, libelle: 'Age' }] }]) }
    let(:dossier) { create(:dossier, procedure:) }
    let(:repetition) { dossier.project_champs_public.find(&:repetition?) }
    let(:row) { dossier.champs.find(&:row?) }

    before { sign_in dossier.user }

    subject { delete :remove, params: { dossier_id: dossier, stable_id: repetition.stable_id, row_id: row.row_id }, format: :turbo_stream }

    context 'removes repetition' do
      it { expect { subject }.not_to change { dossier.reload.champs.size } }
      it { expect { subject }.to change { dossier.reload; dossier.project_champs_public.find(&:repetition?).row_ids.size }.from(1).to(0) }
      it { expect { subject }.to change { row.reload.discarded_at }.from(nil).to(Time) }
    end
  end
end
