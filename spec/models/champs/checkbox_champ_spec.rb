describe Champs::CheckboxChamp do
  it_behaves_like "a boolean champ" do
    let(:boolean_champ) { build(:champ_checkbox, value: value) }
  end

  # TODO remove when normalize_checkbox_values is over
  describe '#true?' do
    let(:checkbox_champ) { build(:champ_checkbox, value: value) }
    subject { checkbox_champ.true? }

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
