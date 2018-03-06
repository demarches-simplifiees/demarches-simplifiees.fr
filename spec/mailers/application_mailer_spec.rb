RSpec.describe ApplicationMailer, type: :mailer do
  let(:mailer) { ApplicationMailer.new }

  describe 'emailable' do
    let(:attestation) { double(size: size) }
    subject { mailer.emailable?(attestation) }

    context 'when the pdf size is acceptable' do
      let(:size) { ApplicationMailer::MAX_SIZE_EMAILABLE }

      it { is_expected.to be true }
    end

    context 'when the pdf size is unacceptable' do
      let(:size) { ApplicationMailer::MAX_SIZE_EMAILABLE + 1 }

      it { is_expected.to be false }
    end
  end

  describe 'add_attachment' do
    subject do
      mailer.add_attachment('test.txt', content, 'descrpition')
      mailer.attachments
    end

    context 'when there is no attachment' do
      let(:content) { nil }

      it { is_expected.to be_empty }
    end

    context 'when there is an attachment' do
      let(:content) { double(read: 'this is a mock pdf', size: size) }

      context 'emailable' do
        let(:size) { 100 }

        it { expect(subject.size).to eq(1) }
        it { expect(subject.first.body.raw_source).to eq('this is a mock pdf') }
      end

      context 'not emailable' do
        let(:size) { ApplicationMailer::MAX_SIZE_EMAILABLE + 1 }

        before { expect(Raven).to receive(:capture_message) }

        it { is_expected.to be_empty }
      end
    end
  end
end
