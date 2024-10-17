# frozen_string_literal: true

describe Champs::LinkedDropDownListChamp do
  describe '#unpack_value' do
    let(:champ) { Champs::LinkedDropDownListChamp.new(value: '["primary", "secondary"]', dossier: build(:dossier)) }
    before { allow(champ).to receive(:type_de_champ).and_return(build(:type_de_champ_linked_drop_down_list)) }

    it { expect(champ.primary_value).to eq('primary') }
    it { expect(champ.secondary_value).to eq('secondary') }
  end

  describe '#primary_value=' do
    let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :linked_drop_down_list }]) }
    let(:dossier) { create(:dossier, procedure:) }
    let(:champ) { dossier.champs.first }

    before { champ.primary_value = '' }

    it {
      champ.primary_value = 'primary'
      expect(champ.value).to eq('["primary",null]')
      champ.secondary_value = 'secondary'
      expect(champ.value).to eq('["primary","secondary"]')
      champ.primary_value = ''
      expect(champ.value).to eq('["",""]')
    }
  end

  describe '#to_s' do
    let(:champ) { Champs::LinkedDropDownListChamp.new(value: [primary_value, secondary_value].to_json) }
    before { allow(champ).to receive(:type_de_champ).and_return(build(:type_de_champ_linked_drop_down_list)) }
    let(:primary_value) { nil }
    let(:secondary_value) { nil }

    subject { champ.to_s }

    context 'with no value' do
      it { is_expected.to eq('') }
    end

    context 'with primary value' do
      let(:primary_value) { 'primary' }

      it { is_expected.to eq('primary') }
    end

    context 'with secondary value' do
      let(:primary_value) { 'primary' }
      let(:secondary_value) { 'secondary' }

      it { is_expected.to eq('primary / secondary') }
    end
  end

  describe 'for_export' do
    let(:champ) { Champs::LinkedDropDownListChamp.new(value:) }
    let(:value) { [primary_value, secondary_value].to_json }
    let(:primary_value) { nil }
    let(:secondary_value) { nil }

    before { allow(champ).to receive(:type_de_champ).and_return(build(:type_de_champ_linked_drop_down_list)) }
    subject { champ.type_de_champ.champ_value_for_export(champ) }

    context 'with no value' do
      let(:value) { nil }

      it { is_expected.to be_nil }
    end

    context 'with primary value' do
      let(:primary_value) { 'primary' }

      it { is_expected.to eq('primary;') }
    end

    context 'with secondary value' do
      let(:primary_value) { 'primary' }
      let(:secondary_value) { 'secondary' }

      it { is_expected.to eq('primary;secondary') }
    end
  end

  describe '#mandatory_and_blank' do
    let(:options) { ["--Primary--", "Secondary"] }

    subject { described_class.new }
    before { allow(subject).to receive(:type_de_champ).and_return(type_de_champ) }

    context 'when the champ is not mandatory' do
      let(:type_de_champ) { build(:type_de_champ_linked_drop_down_list, mandatory: false, drop_down_options: options) }

      it 'blank is fine' do
        is_expected.not_to be_mandatory_blank
      end
    end

    context 'when the champ is mandatory' do
      let(:type_de_champ) { build(:type_de_champ_linked_drop_down_list, mandatory: true, drop_down_options: options) }

      context 'when there is no value' do
        it { is_expected.to be_mandatory_blank }
      end

      context 'when there is a primary value' do
        before { subject.primary_value = 'Primary' }

        context 'when there is no secondary value' do
          it { is_expected.to be_mandatory_blank }
        end

        context 'when there is a secondary value' do
          before { subject.secondary_value = 'Secondary' }

          it { is_expected.not_to be_mandatory_blank }
        end

        context 'when there is nothing to select for the secondary value' do
          let(:options) { ["--A--", "Abbott", "Abelard", "--B--", "--C--", "Cynthia"] }
          before { subject.primary_value = 'B' }

          it { is_expected.not_to be_mandatory_blank }
        end
      end
    end
  end
end
