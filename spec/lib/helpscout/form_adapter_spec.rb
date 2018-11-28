require 'spec_helper'

describe Helpscout::FormAdapter do
  describe '#send_form' do
    let(:api) { spy(double(:api)) }

    context 'create_conversation' do
      before do
        allow(api).to receive(:create_conversation)
          .and_return(double(success?: false))
        described_class.new(params, api).send_form
      end

      let(:params) {
        {
          email: email,
          subject: subject,
          text: text
        }
      }
      let(:email) { 'paul.chavard@beta.gouv.fr' }
      let(:subject) { 'Bonjour' }
      let(:text) { "J'ai un problem" }

      it 'should call method' do
        expect(api).to have_received(:create_conversation)
          .with(email, subject, text, nil)
      end
    end

    context 'add_tags' do
      before do
        allow(api).to receive(:create_conversation)
          .and_return(
            double(
              success?: true,
              headers: {
                'Resource-ID' => conversation_id
              }
            )
          )

        described_class.new(params, api).send_form
      end

      let(:params) {
        {
          email: email,
          subject: subject,
          text: text,
          tags: tags
        }
      }
      let(:email) { 'paul.chavard@beta.gouv.fr' }
      let(:subject) { 'Bonjour' }
      let(:text) { "J'ai un problem" }
      let(:tags) { ['info demarche'] }
      let(:conversation_id) { '123' }

      it 'should call method' do
        expect(api).to have_received(:create_conversation)
          .with(email, subject, text, nil)
        expect(api).to have_received(:add_tags)
          .with(conversation_id, tags)
        expect(api).to have_received(:add_custom_fields)
          .with(conversation_id, nil, nil)
      end
    end

    context 'add_phone' do
      before do
        allow(api).to receive(:create_conversation)
          .and_return(
            double(
              success?: true,
              headers: {
                'Resource-ID' => conversation_id
              }
            )
          )

        described_class.new(params, api).send_form
      end

      let(:params) {
        {
          email: email,
          subject: subject,
          text: text,
          phone: '0666666666'
        }
      }
      let(:phone) { '0666666666' }
      let(:email) { 'paul.chavard@beta.gouv.fr' }
      let(:subject) { 'Bonjour' }
      let(:text) { "J'ai un problem" }
      let(:tags) { ['info demarche'] }
      let(:conversation_id) { '123' }

      it 'should call method' do
        expect(api).to have_received(:create_conversation)
          .with(email, subject, text, nil)
        expect(api).to have_received(:add_phone_number)
          .with(email, phone)
        expect(api).to have_received(:add_custom_fields)
          .with(conversation_id, nil, nil)
      end
    end
  end
end
