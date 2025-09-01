# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Crisp::WebhookProcessor do
  let!(:user) { users(:default_user) }
  let(:event) { "message:send" }
  let(:email) { user.email }
  let(:session_id) { "session_d57cb2d9-4607-42fe-a6be-000001112222" }
  let(:params) do
    {
      event:,
      data: {
        session_id:,
        from: "user",
        user: {
          user_id: email
        }
      }
    }
  end
  let(:processor) { described_class.new(params) }

  subject { processor.process }

  describe '#process' do
    context 'with message:send event' do
      it 'enqueue a job which will update people data' do
        expect { subject }.to have_enqueued_job(CrispUpdatePeopleDataJob).with(user)
      end
    end

    context 'with another event' do
      let(:event) { "other:event" }

      it 'does not handle webhook' do
        expect { subject }.not_to have_enqueued_job
      end
    end

    context 'with a session id instead of email' do
      let(:email) { session_id } # simulate real payload !
      before do
        stub_request(:get, %r{^https://api.crisp.chat/v1/website/.+/conversation/.+/meta$})
          .and_return(
            body: { "error" => false, "reason" => "resolved", "data" => { "email" => user.email } }.to_json
          )
      end

      it 'fetch email from API' do
        expect { subject }.to have_enqueued_job.with(user)
      end
    end

    context 'with unknown user' do
      let(:email) { 'nonexistent@example.com' }

      it 'ignores webhook' do
        expect { subject }.not_to have_enqueued_job
      end
    end
  end
end
