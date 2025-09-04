# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CrispMattermostTechNotificationJob, type: :job do
  let(:user) { users(:default_user) }
  let(:session_id) { "session_310b13c9-f115-42f5-bd83-f5e22b8e50dd" }
  let(:website_id) { "test-website-id" }
  let(:inbox_id) { "123-456" }
  let(:job) { described_class.new(session_id) }
  let(:webhook_url) { "https://mattermost.example.com/webhook" }

  subject { job.perform_now }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("CRISP_WEBSITE_ID").and_return(website_id)
    allow(ENV).to receive(:fetch).with("CRISP_CLIENT_IDENTIFIER").and_return("test-client-id")
    allow(ENV).to receive(:fetch).with("CRISP_CLIENT_KEY").and_return("test-client-key")
    allow(ENV).to receive(:fetch).with("CRISP_INBOX_ID_DEV", nil).and_return("123-456")
    allow(ENV).to receive(:fetch).with("SUPPORT_WEBHOOK_URL", nil).and_return(webhook_url)
  end

  describe '#perform' do
    before do
      stub_request(:get, %r{^https://api.crisp.chat/v1/website/#{website_id}/conversation/#{session_id}$})
        .and_return(
          body: {
            "error" => false,
            "reason" => "resolved",
            "data" => {
              "inbox_id" => inbox_id,
              "session_id" => session_id,
              "topic" => "Technical issue with the platform",
              "last_message" => "I need technical help with the platform",
              "waiting_since" => Time.parse("2025-09-02 15:12:12 +02:00").to_i * 1000,
              "meta" => {
                "email" => user.email,
                "segments" => ["customer", "tech"]
              }
            }
          }.to_json
        )
    end

    context 'when inbox matches' do
      before do
        stub_request(:post, webhook_url)
          .and_return(headers: { "content-type" => "text/plain" }, body: "ok")
      end

      it 'formats Mattermost message correctly' do
        subject

        # Vérifier les éléments spécifiques du message
        expected_patterns = [
          /Technical issue with the platform/,
          /I need technical help with the platform/,
          /#{user.email}/,
          /User ##{user.id}/,
          /customer, tech/,
          /02 sept\. 15h12/
        ]

        expected_patterns.each do |pattern|
          expect(a_request(:post, webhook_url)
            .with(body: hash_including("text" => pattern))).to have_been_made
        end
      end
    end

    context 'when inbox is not technical inbox' do
      let(:inbox_id) { "another-inbox" }

      it "does not send notification" do
        subject

        expect(a_request(:post, webhook_url)).not_to have_been_made
      end
    end

    context 'when Mattermost webhook URL is not configured' do
      let(:webhook_url) { nil }

      it 'does not fail' do
        expect { subject }.not_to raise_error
      end
    end
  end
end
