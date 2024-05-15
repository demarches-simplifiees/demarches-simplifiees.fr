describe Champs::EpciChamp, type: :model do
  describe 'validations' do
    subject { champ.validate(:champs_public_value) }

    describe 'code_departement' do
      let(:champ) { build(:champ_epci, code_departement: code_departement) }

      context 'when nil' do
        let(:code_departement) { nil }

        it { is_expected.to be_truthy }
      end

      context 'when empty' do
        let(:code_departement) { '' }

        it { is_expected.to be_falsey }
      end

      context 'when included in the departement codes' do
        let(:code_departement) { "01" }

        it { is_expected.to be_truthy }
      end

      context 'when not included in the departement codes' do
        let(:code_departement) { "totoro" }

        it { is_expected.to be_falsey }
      end
    end

    describe 'external_id' do
      let(:champ) { build(:champ_epci, code_departement: code_departement, external_id: nil) }

      before do
        champ.save!(validate: false)
        champ.update_columns(external_id: external_id)
      end

      context 'when code_departement is nil' do
        let(:code_departement) { nil }
        let(:external_id) { nil }

        it { is_expected.to be_truthy }
      end

      context 'when code_departement is not nil and valid' do
        let(:code_departement) { "01" }

        context 'when external_id is nil' do
          let(:external_id) { nil }

          it { is_expected.to be_truthy }
        end

        context 'when external_id is empty' do
          let(:external_id) { '' }

          it { is_expected.to be_falsey }
        end

        context 'when external_id is included in the epci codes of the departement' do
          let(:external_id) { '200042935' }

          it { is_expected.to be_truthy }
        end

        context 'when external_id is not included in the epci codes of the departement' do
          let(:external_id) { 'totoro' }

          it { is_expected.to be_falsey }
        end
      end
    end

    describe 'value' do
      subject { champ.validate(:champs_public_value) }

      let(:champ) { build(:champ_epci, code_departement: code_departement, external_id: nil, value: nil) }

      before do
        champ.save!(validate: false)
        champ.update_columns(external_id: external_id, value: value)
      end

      context 'when code_departement is nil' do
        let(:code_departement) { nil }
        let(:external_id) { nil }
        let(:value) { nil }

        it { is_expected.to be_truthy }
      end

      context 'when external_id is nil' do
        let(:code_departement) { '01' }
        let(:external_id) { nil }
        let(:value) { nil }

        it { is_expected.to be_truthy }
      end

      context 'when code_departement and external_id are not nil and valid' do
        let(:code_departement) { '01' }
        let(:external_id) { '200042935' }

        context 'when value is nil' do
          let(:value) { nil }

          it { is_expected.to be_truthy }
        end

        context 'when value is in departement epci names' do
          let(:value) { 'CA Haut - Bugey Agglomération' }

          it { is_expected.to be_truthy }
        end

        context 'when value is in departement epci names' do
          let(:value) { 'CA Haut - Bugey Agglomération' }

          it { is_expected.to be_truthy }
        end

        context 'when epci name had been renamed' do
          let(:value) { 'totoro' }

          it 'is valid and updates its own value' do
            expect(subject).to be_truthy
            expect(champ.value).to eq('CA Haut - Bugey Agglomération')
          end
        end

        context 'when value is not in departement epci names nor in departement epci codes' do
          let(:value) { 'totoro' }

          it 'is invalid' do
            allow(APIGeoService).to receive(:epcis).with(champ.code_departement).and_return([])
            expect(subject).to be_falsey
          end
        end
      end
    end
  end

  describe 'value' do
    let(:champ) { build(:champ_epci, external_id: nil, value: nil) }
    let(:epci) { APIGeoService.epcis('01').first }

    it 'with departement and code' do
      champ.code_departement = '01'
      champ.value = epci[:code]
      expect(champ.blank?).to be_falsey
      expect(champ.external_id).to eq(epci[:code])
      expect(champ.value).to eq(epci[:name])
      expect(champ.selected).to eq(epci[:code])
      expect(champ.code).to eq(epci[:code])
      expect(champ.departement?).to be_truthy
      expect(champ.to_s).to eq(epci[:name])
    end
  end
end
