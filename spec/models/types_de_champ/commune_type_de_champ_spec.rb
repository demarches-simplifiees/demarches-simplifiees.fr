# frozen_string_literal: true

describe TypesDeChamp::CommuneTypeDeChamp do
  let(:tdc_commune) { create(:type_de_champ_communes, libelle: 'Ma commune') }

  it { expect(tdc_commune.libelles_for_export).to match_array([['Ma commune', :value], ['Ma commune (Code INSEE)', :code], ['Ma commune (Département)', :departement]]) }

  it "returns columns for export" do
    stable_id = tdc_commune.stable_id
    expect(tdc_commune.columns_for_export).to match_array([
      { source: 'tdc', stable_id:, path: 'value', libelle: "Ma commune" },
      { source: 'tdc', stable_id:, path: 'code', libelle: "Ma commune (Code INSEE)" },
      { source: 'tdc', stable_id:, path: 'departement', libelle: "Ma commune (Département)" }
    ])
  end

  it "returns libelle for path" do
    expect(tdc_commune.libelle_for_path("code")).to eq "Ma commune (Code INSEE)"
  end
end
