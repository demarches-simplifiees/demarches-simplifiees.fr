describe Champs::CommuneChamp do
  let(:type_de_champ) { create(:type_de_champ_communes, libelle: 'Ma commune') }
  let(:champ) { Champs::CommuneChamp.new(value: value, external_id: code_insee, type_de_champ: type_de_champ) }
  let(:value) { 'Châteldon (63290)' }
  let(:code_insee) { '63102' }

  it { expect(champ.value).to eq('Châteldon (63290)') }
  it { expect(champ.external_id).to eq('63102') }
  it { expect(champ.for_export).to eq(['Châteldon (63290)', '63102']) }
end
