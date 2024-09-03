# frozen_string_literal: true

describe Champs::DropDownListChamp do
  describe 'validations' do
    describe 'inclusion' do
      let(:champ) { described_class.new(other:, value:, dossier: build(:dossier)) }
      before { allow(champ).to receive(:type_de_champ).and_return(build(:type_de_champ_drop_down_list, drop_down_other: other)) }
      subject { champ.validate(:champs_public_value) }

      context 'when the other value is accepted' do
        let(:other) { true }

        context 'when the value is blank' do
          let(:value) { '' }

          it { is_expected.to be_truthy }
        end

        context 'when the value is included in the option list' do
          let(:value) { 'val1' }

          it { is_expected.to be_truthy }
        end

        context 'when the value is not included in the option list' do
          let(:value) { 'something else' }

          it { is_expected.to be_truthy }
        end
      end

      context 'when the other value is not accepted' do
        let(:other) { false }

        context 'when the value is blank' do
          let(:value) { '' }

          it { is_expected.to be_truthy }
        end

        context 'when the value is included in the option list' do
          let(:value) { 'val1' }

          it { is_expected.to be_truthy }
        end

        context 'when the value is not included in the option list' do
          let(:value) { 'something else' }

          it { is_expected.to be_falsey }
        end
      end
    end
  end

  describe '#drop_down_other?' do
    let(:drop_down) { described_class.new(dossier: build(:dossier)) }
    before { allow(drop_down).to receive(:type_de_champ).and_return(build(:type_de_champ_drop_down_list)) }

    context 'when drop_down_other is nil' do
      it do
        drop_down.type_de_champ.drop_down_other = nil
        expect(drop_down.drop_down_other?).to be false

        drop_down.type_de_champ.drop_down_other = "0"
        expect(drop_down.drop_down_other?).to be false

        drop_down.type_de_champ.drop_down_other = false
        expect(drop_down.drop_down_other?).to be false

        drop_down.type_de_champ.drop_down_other = "1"
        expect(drop_down.drop_down_other?).to be true

        drop_down.type_de_champ.drop_down_other = true
        expect(drop_down.drop_down_other?).to be true
      end
    end
  end
end
