# frozen_string_literal: true

describe Champs::CheckboxChamp do
  let(:boolean_champ) { described_class.new(value: value) }
  before { allow(boolean_champ).to receive(:type_de_champ).and_return(build(:type_de_champ_checkbox)) }
  it_behaves_like "a boolean champ"

  # TODO remove when normalize_checkbox_values is over
  describe '#true?' do
    subject { boolean_champ.true? }

    context "when the checkbox value is 'on'" do
      let(:value) { 'on' }

      it { is_expected.to eq(true) }
    end

    context "when the checkbox value is 'off'" do
      let(:value) { 'off' }

      it { is_expected.to eq(false) }
    end
  end
end
