# frozen_string_literal: true

describe TypesDeChamp::PieceJustificativeTypeDeChamp do
  describe '#columns' do
    let(:procedure) { create(:procedure, types_de_champ_public: [libelle: 'pj', type: 'piece_justificative', nature:]) }
    let(:pj_tdc) { procedure.active_revision.types_de_champ.first }
    let(:columns) { pj_tdc.columns(procedure:) }
    let(:nature) { nil }

    it { expect(columns.map(&:label)).to match_array(['pj']) }

    context 'when the pj is a RIB' do
      let(:nature) { 'RIB' }
      it { expect(columns.map(&:label)).to match_array(["pj", "pj – BIC", "pj – IBAN", "pj – Nom de la Banque", "pj – Titulaire"]) }
    end
  end
end
