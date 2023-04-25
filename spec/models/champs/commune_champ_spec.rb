describe Champs::CommuneChamp do
  let(:code_insee) { '63102' }
  let(:code_postal) { '63290' }
  let(:code_departement) { '63' }
  let(:champ) { create(:champ_communes, code_postal: code_postal) }

  describe 'value' do
    it 'with code_postal' do
      champ.update(value: code_insee)
      expect(champ.to_s).to eq('Châteldon (63290)')
      expect(champ.name).to eq('Châteldon')
      expect(champ.external_id).to eq(code_insee)
      expect(champ.code).to eq(code_insee)
      expect(champ.code_departement).to eq(code_departement)
      expect(champ.code_postal).to eq(code_postal)
      expect(champ.for_export).to eq(['Châteldon (63290)', '63102', '63 – Puy-de-Dôme'])
      expect(champ.communes.size).to eq(8)
    end
  end

  describe 'code_postal with spaces' do
    let(:code_postal) { ' 63 2 90  ' }

    it 'with code_postal' do
      expect(champ.communes.size).to eq(8)
    end
  end
end
