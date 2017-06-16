RSpec.describe Attestation, type: :model do
  describe 'emailable' do
    let(:attestation) do
      attestation = Attestation.new
      expect(attestation).to receive(:pdf).and_return(double(size: size))
      attestation
    end

    subject { attestation.emailable? }

    context 'when the pdf size is acceptable' do
      let(:size) { Attestation::MAX_SIZE_EMAILABLE }

      it { is_expected.to be true }
    end

    context 'when the pdf size is unacceptable' do
      let(:size) { Attestation::MAX_SIZE_EMAILABLE + 1 }

      it { is_expected.to be false }
    end
  end
end
