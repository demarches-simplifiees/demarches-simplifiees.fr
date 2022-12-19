describe Champs::CheckboxChamp do
  describe '#valid?' do
    subject { build(:champ_checkbox, value: value).tap(&:valid?) }

    context "when the value is 'on'" do
      let(:value) { 'on' }

      it { is_expected.to be_valid }
    end

    context "when the value is 'off'" do
      let(:value) { 'off' }

      it { is_expected.to be_valid }
    end

    context "when the value is nil" do
      let(:value) { nil }

      it { is_expected.to be_valid }
    end

    context "when the value is blank" do
      let(:value) { "" }

      it { is_expected.not_to be_valid }
    end

    context "when the value is something else" do
      let(:value) { "something else" }

      it { is_expected.not_to be_valid }
    end
  end

  describe '#to_s' do
    subject { Champs::CheckboxChamp.new(value: value).to_s }

    context 'when the value is on' do
      let(:value) { 'on' }

      it { is_expected.to eq('Oui') }
    end

    context 'when the value is off' do
      let(:value) { 'off' }

      it { is_expected.to eq('Non') }
    end
  end
end
