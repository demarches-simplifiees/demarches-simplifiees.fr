describe Champs::EpciChamp, type: :model do
  let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }

  before do
    allow(Rails).to receive(:cache).and_return(memory_store)
    Rails.cache.clear
  end

  let(:champ) { described_class.new }

  describe 'value', vcr: { cassette_name: 'api_geo_epcis' } do
    it 'with departement and code' do
      champ.code_departement = '01'
      champ.value = '200042935'
      expect(champ.external_id).to eq('200042935')
      expect(champ.value).to eq('CA Haut - Bugey Agglomération')
      expect(champ.selected).to eq('200042935')
      expect(champ.code).to eq('200042935')
      expect(champ.departement?).to be_truthy
      expect(champ.to_s).to eq('CA Haut - Bugey Agglomération')
    end
  end
end
