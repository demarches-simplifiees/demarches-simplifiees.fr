describe Champs::CommuneChamp do
  let(:code_insee) { '63102' }
  let(:code_postal) { '63290' }
  let(:code_departement) { '63' }
  let(:champ) { create(:champ_communes, code_postal:, external_id: code_insee) }

  describe 'value' do
    it 'find commune' do
      expect(champ.to_s).to eq('Châteldon (63290)')
      expect(champ.name).to eq('Châteldon')
      expect(champ.external_id).to eq(code_insee)
      expect(champ.code).to eq(code_insee)
      expect(champ.code_departement).to eq(code_departement)
      expect(champ.code_postal).to eq(code_postal)
      expect(champ.for_export(:value)).to eq 'Châteldon (63290)'
      expect(champ.for_export(:code)).to eq '63102'
      expect(champ.for_export(:departement)).to eq '63 – Puy-de-Dôme'
    end

    context 'with code' do
      let(:champ) { create(:champ_communes, code: '63102-63290') }

      it 'find commune' do
        expect(champ.to_s).to eq('Châteldon (63290)')
        expect(champ.name).to eq('Châteldon')
        expect(champ.external_id).to eq(code_insee)
        expect(champ.code).to eq(code_insee)
        expect(champ.code_departement).to eq(code_departement)
        expect(champ.code_postal).to eq(code_postal)
        expect(champ.for_export(:value)).to eq 'Châteldon (63290)'
        expect(champ.for_export(:code)).to eq '63102'
        expect(champ.for_export(:departement)).to eq '63 – Puy-de-Dôme'
      end
    end
  end
end
