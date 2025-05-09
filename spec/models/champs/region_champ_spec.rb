describe Champs::RegionChamp, type: :model do
  let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :regions, stable_id: 99 }]) }
  let(:dossier) { create(:dossier, procedure:) }

  describe 'validations' do
    describe 'external link' do
      let(:champ) do
        described_class
          .new(stable_id: 99, dossier:)
          .tap do |champ|
            champ.value = nil
            champ.external_id = external_id
          end
      end
      subject { champ.validate(:champs_public_value) }
      context 'when nil' do
        let(:external_id) { nil }

        it { is_expected.to be_truthy }
      end

      context 'when blank' do
        let(:external_id) { '' }

        it { is_expected.to be_falsey }
      end

      context 'when included in the region codes' do
        let(:external_id) { "01" }

        it { is_expected.to be_truthy }
      end

      context 'when not included in the region codes' do
        let(:external_id) { "totoro" }

        it { is_expected.to be_falsey }
      end
    end

    describe 'value' do
      let(:champ) do
        described_class
          .new(stable_id: 99, dossier:)
          .tap do |champ|
            champ.value = value
          end
      end
      subject { champ.validate(:champs_public_value) }

      context 'when nil' do
        let(:value) { nil }

        it { is_expected.to be_truthy }
      end

      # not real use case, the value= method override value when blank? aka "" to nil
      context 'when blank' do
        let(:value) { '' }

        xit { is_expected.to be_falsey }
      end

      context 'when included in the region names' do
        let(:value) { "Guyane" }

        it { is_expected.to be_truthy }
      end

      context 'when not included in the region names' do
        let(:value) { "totoro" }

        it { is_expected.to be_falsey }
      end
    end
  end

  describe 'value' do
    let(:champ) do
      described_class.new(stable_id: 99, dossier:)
    end

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
