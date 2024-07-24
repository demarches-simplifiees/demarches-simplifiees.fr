require 'rails_helper'

RSpec.describe HelpscoutCreateConversationJob, type: :job do
  let(:api) { instance_double("Helpscout::API") }
  let(:email) { 'help@rspec.net' }
  let(:subject_text) { 'Bonjour' }
  let(:text) { "J'ai un pb" }
  let(:tags) { ["first tag"] }
  let(:phone) { nil }
  let(:params) {
            {
              email:,
              subject: subject_text,
              text:,
              tags:,
              phone:
            }
          }

  describe '#perform' do
    before do
      allow(Helpscout::API).to receive(:new).and_return(api)
      allow(api).to receive(:create_conversation)
        .and_return(double(
              success?: true,
              headers: { 'Resource-ID' => 'new-conversation-id' }
            ))
      allow(api).to receive(:add_tags)
      allow(api).to receive(:add_phone_number) if params[:phone].present?
    end

    subject {
      described_class.perform_now(**params)
    }

    context 'when blob_id is not present' do
      it 'sends the form without a file' do
        subject
        expect(api).to have_received(:create_conversation).with(email, subject_text, text, nil)
        expect(api).to have_received(:add_tags).with("new-conversation-id", tags)
      end
    end

    context 'when blob_id is present' do
      let(:blob) {
        ActiveStorage::Blob.create_and_upload!(io: StringIO.new("toto"), filename: "toto.png")
      }
      let(:params) { super().merge(blob_id: blob.id) }

      before do
        allow(blob).to receive(:virus_scanner).and_return(double('VirusScanner', pending?: pending, safe?: safe))
        allow(ActiveStorage::Blob).to receive(:find).with(blob.id).and_return(blob)
      end

      context 'when the file has not been scanned yet' do
        let(:pending) { true }
        let(:safe) { false }

        it 'reenqueue job' do
          expect { subject }.to have_enqueued_job(described_class).with(params)
        end
      end

      context 'when the file is safe' do
        let(:pending) { false }
        let(:safe) { true }

        it 'downloads the file and sends the form' do
          subject
          expect(api).to have_received(:create_conversation).with(email, subject_text, text, blob)
        end
      end

      context 'when the file is not safe' do
        let(:pending) { false }
        let(:safe) { false }

        it 'ignore the file' do
          subject
          expect(api).to have_received(:create_conversation).with(email, subject_text, text, nil)
        end
      end
    end

    context 'with a phone' do
      let(:phone) { "06" }
      it 'associates the phone number' do
        subject
        expect(api).to have_received(:add_phone_number).with(email, phone)
      end
    end
  end
end
