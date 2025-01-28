# frozen_string_literal: true

describe Champs::LinkedDropDownListChamp do
  let(:types_de_champ_public) do
    if options.nil?
      [{ type: :linked_drop_down_list, mandatory: }]
    else
      [{ type: :linked_drop_down_list, mandatory:, options: }]
    end
  end
  let(:procedure) { create(:procedure, types_de_champ_public:) }
  let(:dossier) { create(:dossier, procedure:) }
  let(:champ) { dossier.champs.first.tap { _1.update(value:) } }
  let(:value) { nil }
  let(:mandatory) { true }
  let(:options) { nil }

  describe '#unpack_value' do
    let(:value) { '["primary", "secondary"]' }

    it { expect(champ.primary_value).to eq('primary') }
    it { expect(champ.secondary_value).to eq('secondary') }
  end

  describe '#primary_value=' do
    before { champ.primary_value = '' }

    it {
      champ.primary_value = 'primary'
      expect(champ.value).to eq('["primary",""]')
      champ.secondary_value = 'secondary'
      expect(champ.value).to eq('["primary","secondary"]')
      champ.primary_value = ''
      expect(champ.value).to eq('["",""]')
    }
  end

  describe '#to_s' do
    let(:value) { [primary_value, secondary_value].to_json }
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
    let(:value) { [primary_value, secondary_value].to_json }
    let(:primary_value) { nil }
    let(:secondary_value) { nil }

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

    subject { champ }

    context 'when the champ is not mandatory' do
      let(:mandatory) { false }

      it 'blank is fine' do
        is_expected.not_to be_mandatory_blank
      end
    end

    context 'when the champ is mandatory' do
      context 'when there is no value' do
        it { is_expected.to be_mandatory_blank }
      end

      context 'when there is a primary value' do
        before { champ.primary_value = 'Primary' }

        context 'when there is no secondary value' do
          it { is_expected.to be_mandatory_blank }
        end

        context 'when there is a secondary value' do
          before { champ.secondary_value = 'Secondary' }

          it { is_expected.not_to be_mandatory_blank }
        end

        context 'when there is nothing to select for the secondary value' do
          let(:options) { ["--A--", "Abbott", "Abelard", "--B--", "--C--", "Cynthia"] }
          before { champ.primary_value = 'B' }

          it { is_expected.not_to be_mandatory_blank }
        end
      end
    end
  end
end
