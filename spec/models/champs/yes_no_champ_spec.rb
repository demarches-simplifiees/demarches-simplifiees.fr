describe Champs::YesNoChamp do
  describe '#valid?' do
    subject { build(:champ_yes_no, value: value).tap(&:valid?) }

    context "when the value is 'true'" do
      let(:value) { 'true' }

      it { is_expected.to be_valid }
    end

    context "when the value is 'false'" do
      let(:value) { 'false' }

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
    subject { Champs::YesNoChamp.new(value: value).to_s }

    context 'when the value is false' do
      let(:value) { "false" }

      it { is_expected.to eq("Non") }
    end

    context 'when the value is true' do
      let(:value) { "true" }

      it { is_expected.to eq("Oui") }
    end

    context 'when the value is nil' do
      let(:value) { nil }

      it { is_expected.to eq("Non") }
    end
  end
end
