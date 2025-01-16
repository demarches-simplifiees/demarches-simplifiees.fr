require 'rails_helper'

RSpec.describe HelpscoutCreateConversationJob, type: :job do
  let(:args) { { email: 'sender@email.com' } }

  describe '#perform' do
    context 'when blob_id is not present' do
      it 'sends the form without a file' do
        form_adapter = double('Helpscout::FormAdapter')
        allow(Helpscout::FormAdapter).to receive(:new).with(hash_including(args.merge(blob: nil))).and_return(form_adapter)
        expect(form_adapter).to receive(:send_form)

        described_class.perform_now(**args)
      end
    end

    context 'when blob_id is present' do
      let(:blob) {
        ActiveStorage::Blob.create_and_upload!(io: StringIO.new("toto"), filename: "toto.png")
      }

      before do
        allow(blob).to receive(:virus_scanner).and_return(double('VirusScanner', pending?: pending, safe?: safe))
      end

      context 'when the file has not been scanned yet' do
        let(:pending) { true }
        let(:safe) { false }

        it 'reenqueue job' do
          expect {
            described_class.perform_now(blob_id: blob.id, **args)
          }.to have_enqueued_job(described_class).with(blob_id: blob.id, **args)
        end
      end

      context 'when the file is safe' do
        let(:pending) { false }
        let(:safe) { true }

        it 'downloads the file and sends the form' do
          form_adapter = double('Helpscout::FormAdapter')
          allow(Helpscout::FormAdapter).to receive(:new).with(hash_including(args.merge(blob:))).and_return(form_adapter)
          allow(form_adapter).to receive(:send_form)

          described_class.perform_now(blob_id: blob.id, **args)
        end
      end

      context 'when the file is not safe' do
        let(:pending) { false }
        let(:safe) { false }

        it 'downloads the file and sends the form' do
          form_adapter = double('Helpscout::FormAdapter')
          allow(Helpscout::FormAdapter).to receive(:new).with(hash_including(args.merge(blob: nil))).and_return(form_adapter)
          allow(form_adapter).to receive(:send_form)

          described_class.perform_now(blob_id: blob.id, **args)
        end
      end
    end
  end
end
