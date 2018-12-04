require 'rails_helper'
include ActiveJob::TestHelper

describe WebhookController, type: :controller do
  describe "#mailjet" do
    let(:payload) { JSON.parse(File.read('spec/fixtures/files/mailjet/parse_api.json')) }
    let(:dossier) { create(:dossier, :en_construction) }

    before do
      payload['CustomID'] = dossier.id.to_s
      payload['From'] = dossier.user.email
    end

    subject { post :mailjet, params: payload }

    context 'when the payload is valid' do
      it 'posts the email payload as a comment' do
        expect { subject }.to change(Commentaire, :count).by(1)
        expect(Commentaire.last.dossier).to eq(dossier)
        expect(Commentaire.last.body).to include('Bonjour')
      end

      it 'doesn’t report any errors' do
        expect(Raven).not_to receive(:capture_message)
        subject
      end

      it 'tells Mailjet that the inbound email was processed' do
        expect(subject.status).to eq 200
      end
    end

    shared_examples 'an inbound error' do
      it 'doesn’t post a comment' do
        expect { subject }.not_to change(Commentaire, :count)
      end

      it 'sends an error email to the sender' do
        perform_enqueued_jobs do
          expect { subject }.to change(ActionMailer::Base.deliveries, :count).by(1)
          expect(ActionMailer::Base.deliveries.last.to).to eq([payload['From']])
        end
      end

      it 'reports the error to Sentry' do
        expect(Raven).to receive(:capture_message)
        subject
      end

      it 'tells Mailjet that the inbound email was processed' do
        expect(subject.status).to eq(204)
      end
    end

    context 'when the dossier doesn’t exist' do
      before do
        payload['CustomID'] = 'invalid-dossier-id'
      end

      it_behaves_like 'an inbound error'
    end

    context 'when the message is not from the dossier owner' do
      before do
        payload['From'] = 'random_person@ds.fr'
      end

      it_behaves_like 'an inbound error'
    end

    context 'when the received message is empty' do
      before do
        payload['Text-part'] = ''
        payload.delete('Html-part')
      end

      it_behaves_like 'an inbound error'
    end

    context 'when the comment can’t be saved' do
      before do
        invalid_comment = Commentaire.new
        allow(CommentaireService).to receive(:create).and_return(invalid_comment)
      end

      it_behaves_like 'an inbound error'
    end
  end
end
