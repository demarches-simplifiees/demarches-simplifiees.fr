# frozen_string_literal: true

describe Champs::RepetitionController, type: :controller do
  describe '#remove' do
    let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :repetition, mandatory: true, children: [{ libelle: 'Nom' }, { type: :integer_number, libelle: 'Age' }] }]) }
    let(:dossier) { create(:dossier, procedure: procedure) }

    before { sign_in dossier.user }
    it 'removes repetition' do
      rows, repetitions = dossier.champs.partition(&:child?)
      repetition = repetitions.first
      expect { delete :remove, params: { dossier_id: repetition.dossier, stable_id: repetition.stable_id, row_id: rows.first.row_id }, format: :turbo_stream }
        .to change { dossier.reload.champs.size }.from(3).to(1)
    end
  end
end
