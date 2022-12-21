RSpec.shared_examples "a boolean champ" do
  describe 'before validation' do
    subject { boolean_champ.valid? }

    context "when the value is blank" do
      let(:value) { "" }

      it "normalizes the value to nil" do
        expect { subject }.to change { boolean_champ.value }.from(value).to(nil)
      end
    end
  end

  describe '#to_s' do
    subject { boolean_champ.to_s }

    context 'when the value is false' do
      let(:value) { 'false' }

      it { is_expected.to eq('Non') }
    end

    context 'when the value is true' do
      let(:value) { 'true' }

      it { is_expected.to eq('Oui') }
    end

    context 'when the value is nil' do
      let(:value) { nil }

      it { is_expected.to eq("Non") }
    end
  end
end
