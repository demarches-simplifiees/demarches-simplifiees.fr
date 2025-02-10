# frozen_string_literal: true

RSpec.describe Dolist::APISender do
  let(:mail) { instance_double('Mail::Message') }
  let(:api_client) { instance_double('Dolist::API') }
  subject { described_class.new(mail) }

  before do
    allow(Dolist::API).to receive(:new).and_return(api_client)
  end

  describe '#deliver!' do
    context 'when rate limited' do
      before do
        allow(Dolist::API).to receive(:rate_limited?).and_return(true)
        allow_any_instance_of(Kernel).to receive(:rand).and_return(0.05) # Pour tester Sentry
      end

      it 'raises RateLimitError' do
        expect { subject.deliver!(mail) }.to raise_error(Dolist::RateLimitError)
      end

      it 'notifies Sentry 10% of the time' do
        expect(Sentry).to receive(:capture_message).with("Dolist: rate limit reached")
        expect { subject.deliver!(mail) }.to raise_error(Dolist::RateLimitError)
      end
    end

    context 'when API call succeeds' do
      let(:response) { { "Result" => "message-id-123" } }

      before do
        allow(api_client).to receive(:send_email).and_return(response)
        allow(mail).to receive(:message_id=)
      end

      it 'sets message_id on mail' do
        expect(mail).to receive(:message_id=).with("message-id-123")
        subject.deliver!(mail)
      end
    end
  end
end
