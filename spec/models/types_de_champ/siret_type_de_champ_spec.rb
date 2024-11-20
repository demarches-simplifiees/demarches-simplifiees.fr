# frozen_string_literal: true

describe TypesDeChamp::SiretTypeDeChamp do
  let(:tdc_siret) { build(:type_de_champ_siret, libelle: 'Numéro SIRET') }
  let(:procedure) { build(:procedure) }

  describe "#columns" do
    subject(:columns) { tdc_siret.columns(procedure: procedure) }

    it "includes required jsonpaths" do
      expected_paths = [
        "$.entreprise_raison_sociale",
        "$.entreprise_siren"
      ]

      json_columns = columns.filter { _1.is_a?(Columns::JSONPathColumn) }
      expect(json_columns.map(&:jsonpath)).to include(*expected_paths)
    end

    it "includes address columns" do
      address_columns = columns.filter { _1.is_a?(Columns::JSONPathColumn) && _1.jsonpath.match?(/adresse|postal_code/) }

      expect(address_columns).not_to be_empty
    end

    it "does not include jsonpath SIRET column" do
      expect(columns.find { |c| c.is_a?(Columns::JSONPathColumn) && c.jsonpath == "$.siret" }).to be_nil
    end
  end
end
