describe Champs::DepartementChamp, type: :model do
  describe 'validations' do
    describe 'external link' do
      let(:champ) { described_class.new(external_id: external_id, dossier: build(:dossier)) }
      before { allow(champ).to receive(:type_de_champ).and_return(build(:type_de_champ_departements)) }
      subject { champ.validate(:champs_public_value) }

      context 'when nil' do
        let(:external_id) { nil }

        it { is_expected.to be_truthy }
      end

      context 'when blank' do
        let(:external_id) { '' }

        it { is_expected.to be_falsey }
      end

      context 'when included in the departement codes' do
        let(:external_id) { "01" }

        it { is_expected.to be_truthy }
      end

      context 'when not included in the departement codes' do
        let(:external_id) { "totoro" }

        it { is_expected.to be_falsey }
      end
    end

    describe 'value' do
      let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :departements }]) }
      let(:dossier) { create(:dossier, procedure:) }
      let(:champ) { dossier.champs.first }
      subject { champ.validate(:champs_public_value) }
      before { champ.update_columns(value: value) }

      context 'when nil' do
        let(:value) { nil }

        it { is_expected.to be_truthy }
      end

      context 'when blank' do
        let(:value) { '' }

        it { is_expected.to be_falsey }
      end

      context 'when included in the departement names' do
        let(:value) { "Ain" }

        it { is_expected.to be_truthy }
      end

      context 'when not included in the departement names' do
        let(:value) { "totoro" }

        it { is_expected.to be_falsey }
      end
    end
  end

  describe 'value' do
    let(:champ) { described_class.new(value: nil, dossier: build(:dossier)) }
    before { allow(champ).to receive(:type_de_champ).and_return(build(:type_de_champ_departements)) }

    it 'with code having 2 chars' do
      champ.value = '01'
      expect(champ.external_id).to eq('01')
      expect(champ.code).to eq('01')
      expect(champ.name).to eq('Ain')
      expect(champ.value).to eq('Ain')
      expect(champ.selected).to eq('01')
      expect(champ.to_s).to eq('01 – Ain')
      expect(champ.for_api_v2).to eq('01 - Ain')
    end

    it 'with code having 3 chars' do
      champ.value = '971'
      expect(champ.external_id).to eq('971')
      expect(champ.code).to eq('971')
      expect(champ.name).to eq('Guadeloupe')
      expect(champ.value).to eq('Guadeloupe')
      expect(champ.selected).to eq('971')
      expect(champ.to_s).to eq('971 – Guadeloupe')
    end

    it 'with alphanumeric code' do
      champ.value = '2B'
      expect(champ.external_id).to eq('2B')
      expect(champ.code).to eq('2B')
      expect(champ.name).to eq('Haute-Corse')
      expect(champ.value).to eq('Haute-Corse')
      expect(champ.selected).to eq('2B')
      expect(champ.to_s).to eq('2B – Haute-Corse')
    end

    it 'with nil' do
      champ.write_attribute(:value, 'Ain')
      champ.write_attribute(:external_id, '01')
      champ.value = nil
      expect(champ.external_id).to be_nil
      expect(champ.code).to be_nil
      expect(champ.name).to be_nil
      expect(champ.value).to be_nil
      expect(champ.selected).to be_nil
      expect(champ.to_s).to eq('')
    end

    it 'with blank' do
      champ.write_attribute(:value, 'Ain')
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
      expect(champ.code).to be_nil
      expect(champ.name).to be_nil
      expect(champ.value).to be_nil
      expect(champ.selected).to be_nil
      expect(champ.to_s).to eq('')
    end

    it 'with initial code and name' do
      champ.write_attribute(:value, '01 - Ain')
      expect(champ.external_id).to be_nil
      expect(champ.code).to eq('01')
      expect(champ.name).to eq('Ain')
      expect(champ.value).to eq('01 - Ain')
      expect(champ.selected).to eq('01')
      expect(champ.to_s).to eq('01 – Ain')
    end

    it 'with initial code and alphanumeric name' do
      champ.write_attribute(:value, '2B - Haute-Corse')
      expect(champ.external_id).to be_nil
      expect(champ.code).to eq('2B')
      expect(champ.name).to eq('Haute-Corse')
      expect(champ.value).to eq('2B - Haute-Corse')
      expect(champ.selected).to eq('2B')
      expect(champ.to_s).to eq('2B – Haute-Corse')
    end
  end
end
