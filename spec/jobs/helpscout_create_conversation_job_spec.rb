require 'rails_helper'

RSpec.describe HelpscoutCreateConversationJob, type: :job do
  let(:api) { instance_double("Helpscout::API") }
  let(:email) { 'help@rspec.net' }
  let(:subject_text) { 'Bonjour' }
  let(:text) { "J'ai un pb" }
  let(:tags) { ["first tag"] }
  let(:question_type) { "lost" }
  let(:phone) { nil }
  let(:user) { nil }
  let(:contact_form) { create(:contact_form, email:, user:, subject: subject_text, text:, tags:, phone:, question_type:) }

  describe '#perform' do
    before do
      allow(Helpscout::API).to receive(:new).and_return(api)
      allow(api).to receive(:create_conversation)
        .and_return(double(
              success?: true,
              headers: { 'Resource-ID' => 'new-conversation-id' }
            ))
      allow(api).to receive(:add_tags)
      allow(api).to receive(:add_phone_number) if phone.present?
    end

    subject {
      described_class.perform_now(contact_form)
    }

    context 'when no file is attached' do
      it 'sends the form without a file' do
        subject
        expect(api).to have_received(:create_conversation).with(email, subject_text, text, nil)
        expect(api).to have_received(:add_tags).with("new-conversation-id", match_array(tags.concat(["contact form", question_type])))
        expect(contact_form).to be_destroyed
      end
    end

    context 'when a file is attached' do
      before do
        file = fixture_file_upload('spec/fixtures/files/white.png', 'image/png')
        contact_form.piece_jointe.attach(file)
      end

      context 'when the file has not been scanned yet' do
        before do
          allow_any_instance_of(ActiveStorage::Blob).to receive(:virus_scanner).and_return(double('VirusScanner', pending?: true, safe?: false))
        end

        it 'reenqueues job' do
          expect { subject }.to have_enqueued_job(described_class).with(contact_form)
        end
      end

      context 'when the file is safe' do
        before do
          allow_any_instance_of(ActiveStorage::Blob).to receive(:virus_scanner).and_return(double('VirusScanner', pending?: false, safe?: true))
        end

        it 'sends the form with the file' do
          subject
          expect(api).to have_received(:create_conversation).with(email, subject_text, text, contact_form.piece_jointe)
        end
      end

      context 'when the file is not safe' do
        before do
          allow_any_instance_of(ActiveStorage::Blob).to receive(:virus_scanner).and_return(double('VirusScanner', pending?: false, safe?: false))
        end

        it 'ignores the file' do
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

    context 'attached to an user' do
      let(:email) { nil }
      let(:user) { users(:default_user) }

      it 'associates the email from user' do
        subject
        expect(api).to have_received(:create_conversation).with(user.email, subject_text, text, nil)
        expect(contact_form).to be_destroyed
        expect(user.reload).to be_truthy
      end

      context 'having dossiers' do
        before do
          create(:dossier, user:)
        end

        it 'associates the email from user' do
          subject
          expect(api).to have_received(:create_conversation).with(user.email, subject_text, text, nil)
          expect(contact_form).to be_destroyed
          expect(user.reload).to be_truthy
        end
      end
    end
  end
end
