describe Champs::EpciChamp, type: :model do
  describe 'validations' do
    describe 'code_departement' do
      subject { build(:champ_epci, code_departement: code_departement) }

      context 'when nil' do
        let(:code_departement) { nil }

        it { is_expected.to be_valid }
      end

      # pf this test prevent from posting optional epci field as code_departement is then ''
      # cf visa_spec
      #
      # context 'when empty' do
      #   let(:code_departement) { '' }
      #
      #   it { is_expected.not_to be_valid }
      # end

      context 'when included in the departement codes' do
        let(:code_departement) { "01" }

        it { is_expected.to be_valid }
      end

      context 'when not included in the departement codes' do
        let(:code_departement) { "totoro" }

        it { is_expected.not_to be_valid }
      end
    end

    describe 'external_id' do
      let(:champ) { build(:champ_epci, code_departement: code_departement, external_id: nil) }

      subject { champ }

      before do
        champ.save!
        champ.update_columns(external_id: external_id)
      end

      context 'when code_departement is nil' do
        let(:code_departement) { nil }
        let(:external_id) { nil }

        it { is_expected.to be_valid }
      end

      context 'when code_departement is not nil and valid' do
        let(:code_departement) { "01" }

        context 'when external_id is nil' do
          let(:external_id) { nil }

          it { is_expected.to be_valid }
        end

        context 'when external_id is empty' do
          let(:external_id) { '' }

          it { is_expected.not_to be_valid }
        end

        context 'when external_id is included in the epci codes of the departement' do
          let(:external_id) { '200042935' }

          it { is_expected.to be_valid }
        end

        context 'when external_id is not included in the epci codes of the departement' do
          let(:external_id) { 'totoro' }

          it { is_expected.not_to be_valid }
        end
      end
    end

    describe 'value' do
      let(:champ) { build(:champ_epci, code_departement: code_departement, external_id: nil, value: nil) }

      subject { champ }

      before do
        champ.save!
        champ.update_columns(external_id: external_id, value: value)
      end

      context 'when code_departement is nil' do
        let(:code_departement) { nil }
        let(:external_id) { nil }
        let(:value) { nil }

        it { is_expected.to be_valid }
      end

      context 'when external_id is nil' do
        let(:code_departement) { '01' }
        let(:external_id) { nil }
        let(:value) { nil }

        it { is_expected.to be_valid }
      end

      context 'when code_departement and external_id are not nil and valid' do
        let(:code_departement) { '01' }
        let(:external_id) { '200042935' }

        context 'when value is nil' do
          let(:value) { nil }

          it { is_expected.to be_valid }
        end

        context 'when value is empty' do
          let(:value) { '' }

          it { is_expected.not_to be_valid }
        end

        context 'when value is in departement epci names' do
          let(:value) { 'CA Haut - Bugey Agglomération' }

          it { is_expected.to be_valid }
        end

        context 'when value is not in departement epci names' do
          let(:value) { 'totoro' }

          it { is_expected.not_to be_valid }
        end
      end
    end
  end

  describe 'value' do
    let(:champ) { described_class.new }
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
