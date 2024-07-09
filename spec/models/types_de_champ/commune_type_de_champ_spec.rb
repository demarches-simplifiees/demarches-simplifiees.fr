describe TypesDeChamp::CommuneTypeDeChamp do
  let(:tdc_commune) { create(:type_de_champ_communes, libelle: 'Ma commune') }

  it { expect(tdc_commune.libelles_for_export).to match_array([['Ma commune', :value], ['Ma commune (Code INSEE)', :code], ['Ma commune (Département)', :departement]]) }

  it "returns paths for export" do
    stable_id = tdc_commune.stable_id
    expect(tdc_commune.paths_for_export).to match_array([
      { :full_path => "tdc_#{stable_id}_value", :libelle => "Ma commune" },
      { :full_path => "tdc_#{stable_id}_code", :libelle => "Ma commune (Code INSEE)" },
      { :full_path => "tdc_#{stable_id}_departement", :libelle => "Ma commune (Département)" }
    ])
  end

  it "returns libelle for path" do
    expect(tdc_commune.libelle_for_path("code")).to eq "Ma commune (Code INSEE)"
  end
end
