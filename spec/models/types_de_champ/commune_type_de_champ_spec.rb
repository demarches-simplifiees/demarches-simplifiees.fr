describe TypesDeChamp::CommuneTypeDeChamp do
  let(:subject) { create(:type_de_champ_communes, libelle: 'Ma commune') }

  it { expect(subject.libelle_for_export(0)).to eq('Ma commune') }
  it { expect(subject.libelle_for_export(1)).to eq('Ma commune (Code insee)') }
end
