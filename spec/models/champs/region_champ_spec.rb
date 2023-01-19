describe Champs::RegionChamp, type: :model do
  let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }

  before do
    allow(Rails).to receive(:cache).and_return(memory_store)
    Rails.cache.clear
  end

  describe 'validations' do
    describe 'external link' do
      subject { build(:champ_regions, external_id: external_id) }

      context 'when nil' do
        let(:external_id) { nil }

        it { is_expected.to be_valid }
      end

      context 'when blank' do
        let(:external_id) { '' }

        it { is_expected.not_to be_valid }
      end

      context 'when included in the region codes' do
        let(:external_id) { "01" }

        it { is_expected.to be_valid }
      end

      context 'when not included in the region codes' do
        let(:external_id) { "totoro" }

        it { is_expected.not_to be_valid }
      end
    end

    describe 'value' do
      subject { create(:champ_regions) }

      before { subject.update_columns(value: value) }

      context 'when nil' do
        let(:value) { nil }

        it { is_expected.to be_valid }
      end

      context 'when blank' do
        let(:value) { '' }

        it { is_expected.not_to be_valid }
      end

      context 'when included in the region names' do
        let(:value) { "Guyane" }

        it { is_expected.to be_valid }
      end

      context 'when not included in the region names' do
        let(:value) { "totoro" }

        it { is_expected.not_to be_valid }
      end
    end
  end

  describe 'value', vcr: { cassette_name: 'api_geo_regions' } do
    let(:champ) { described_class.new }

    it 'with code' do
      champ.value = '01'
      expect(champ.external_id).to eq('01')
      expect(champ.value).to eq('Guadeloupe')
      expect(champ.selected).to eq('01')
      expect(champ.to_s).to eq('Guadeloupe')
    end

    it 'with nil' do
      champ.write_attribute(:value, 'Guadeloupe')
      champ.write_attribute(:external_id, '01')
      champ.value = nil
      expect(champ.external_id).to be_nil
      expect(champ.value).to be_nil
      expect(champ.selected).to be_nil
      expect(champ.to_s).to eq('')
    end

    it 'with blank' do
      champ.write_attribute(:value, 'Guadeloupe')
      champ.write_attribute(:external_id, '01')
      champ.value = ''
      expect(champ.external_id).to be_nil
      expect(champ.value).to be_nil
      expect(champ.selected).to be_nil
      expect(champ.to_s).to eq('')
    end

    it 'with initial nil' do
      champ.write_attribute(:value, nil)
      expect(champ.external_id).to be_nil
      expect(champ.value).to be_nil
      expect(champ.selected).to be_nil
      expect(champ.to_s).to eq('')
    end

    it 'with initial name' do
      champ.write_attribute(:value, 'Guadeloupe')
      expect(champ.external_id).to be_nil
      expect(champ.value).to eq('Guadeloupe')
      expect(champ.selected).to eq('01')
      expect(champ.to_s).to eq('Guadeloupe')
    end
  end
end
