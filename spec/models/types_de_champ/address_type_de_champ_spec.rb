# frozen_string_literal: true

describe TypesDeChamp::AddressTypeDeChamp do
  describe '#columns' do
    let(:procedure) { create(:procedure, types_de_champ_public: [libelle: 'addr', type: 'address']) }
    let(:address_tdc) { procedure.active_revision.types_de_champ.first }
    let(:columns) { address_tdc.columns(procedure:) }

    it '' do
      expected_columns = [
        "addr",
        "addr – Code postal (5 chiffres)",
        "addr – Commune",
        "addr – Département",
        "addr – Région",
      ]

      expect(columns.map(&:label)).to match_array(expected_columns)
    end
  end
end
