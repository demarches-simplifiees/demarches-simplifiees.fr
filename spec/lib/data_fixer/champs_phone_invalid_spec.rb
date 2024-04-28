# frozen_string_literal: true

describe DataFixer::ChampsPhoneInvalid do
  describe '#fix' do
    subject { described_class.fix(phone_str) }

    context 'when separated evenly with space between and after dash' do
      let(:phone_str) { "0203040506 - 0607080900" }
      it { is_expected.to eq('0607080900') }
    end
    context 'when separated oddly without space after dash' do
      let(:phone_str) { "0203040506 -0607080900" }
      it { is_expected.to eq('0607080900') }
    end
    context 'when separated oddly without space after dash' do
      let(:phone_str) { "0203040506- 0607080900" }
      it { is_expected.to eq('0607080900') }
    end
    context 'when having space inside number' do
      let(:phone_str) { "020 3040 506 - 06070  8 09 00 " }
      it { is_expected.to eq('0607080900') }
    end
  end

  describe '#fixable' do
    subject { described_class.fixable?(phone_str) }

    context 'when separated evenly with space between and after dash' do
      let(:phone_str) { "0203040506 - 0607080900" }
      it { is_expected.to be_truthy }
    end
    context 'when separated oddly without space after dash' do
      let(:phone_str) { "0203040506 -0607080900" }
      it { is_expected.to be_truthy }
    end
    context 'when separated oddly without space after dash' do
      let(:phone_str) { "0203040506- 0607080900" }
      it { is_expected.to be_truthy }
    end
    context 'when having space inside number' do
      let(:phone_str) { "020 3040 506 - 06070  8 09 00 " }
      it { is_expected.to be_truthy }
    end
    context 'when separated by space' do
      let(:phone_str) { "0203040506 0607080900" }
      it { is_expected.to be_falsey }
    end
  end
end
