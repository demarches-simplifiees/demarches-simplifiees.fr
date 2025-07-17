# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Crisp::WebhookProcessor do
  let!(:user) { users(:default_user) }
  let(:event) { "message:send" }
  let(:email) { user.email }
  let(:params) do
    {
      event:,
      data: {
        user: {
          user_id: email
        }
      }
    }
  end
  let(:processor) { described_class.new(params) }

  subject { processor.process }

  describe '#process' do
    let(:url_regex) do
      %r{\Ahttps://api\.crisp\.chat/v1/website/#{ENV['CRISP_WEBSITE_ID']}/people/data/.*\z}
    end

    context 'with event message:send' do
      before do
        stub_request(:patch, url_regex).and_return(body: {
          error: false, reason: "updated", data: {}
        }.to_json)
      end

      it 'updates people data by calling Crisp API with expected body and headers' do
        expect(subject).to be_success

        expect(a_request(:patch, url_regex).with(headers: {
          'X-Crisp-Tier' => 'Plugin',
          'Authorization' => /Basic /
        }, body: /Liens/)).to have_been_made.once
      end
    end

    context 'with another event' do
      let(:event) { "other:event" }

      it 'does not handle webhook' do
        subject

        expect(a_request(:patch, url_regex)).not_to have_been_made
      end
    end

    context 'with unknown user' do
      let(:email) { 'nonexistent@example.com' }

      it 'ignores webhook' do
        subject

        expect(a_request(:patch, url_regex)).not_to have_been_made
      end
    end
  end
end
