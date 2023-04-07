describe Champs::CommuneChamp do
  let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }

  before do
    allow(Rails).to receive(:cache).and_return(memory_store)
    Rails.cache.clear
  end

  let(:code_insee) { '63102' }
  let(:code_postal) { '63290' }
  let(:code_departement) { '63' }

  describe 'value', vcr: { cassette_name: 'api_geo_communes' } do
    let(:champ) { create(:champ_communes, code_postal: code_postal) }

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

    context 'when code_postal is nil', vcr: { cassette_name: 'api_geo_communes' } do
      let(:champ) { create(:champ_communes, external_id: code_insee, code_departement:) }

      it 'with value' do
        champ.update_column(:value, 'Châteldon (63290)')
        expect(champ.to_s).to eq('Châteldon (63290)')
        expect(champ.name).to eq('Châteldon')
        expect(champ.external_id).to eq(code_insee)
        expect(champ.code).to eq(code_insee)
        expect(champ.code_departement).to eq(code_departement)
        expect(champ.code_postal).to be_nil
        expect(champ.code_postal_with_fallback).to eq(code_postal)
        expect(champ.for_export).to eq(['Châteldon (63290)', '63102', '63 – Puy-de-Dôme'])
        expect(champ.communes.size).to eq(8)
      end
    end
  end
end
