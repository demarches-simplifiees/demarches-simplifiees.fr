describe Champs::RepetitionController, type: :controller do
  describe '#remove' do
    let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :repetition, children: [{ libelle: 'Nom' }, { type: :integer_number, libelle: 'Age' }] }]) }
    let(:dossier) { create(:dossier, procedure: procedure) }

    before { sign_in dossier.user }
    it 'removes repetition' do
      rows, repetitions = dossier.champs.partition { _1.parent_id.present? }
      expect { delete :remove, params: { champ_id: repetitions.first.id, row_id: rows.first.row_id }, format: :turbo_stream }
        .to change { dossier.reload.champs.size }.from(3).to(1)
    end
  end
end
