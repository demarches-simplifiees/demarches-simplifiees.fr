describe Champs::YesNoChamp do
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
