# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CrispUpdatePeopleDataJob, type: :job do
  let(:user) { users(:default_user) }
  let(:session_id) { "session_d57cb2d9-4607-42fe-a6be-000001112222" }
  let(:email) { nil }
  let(:job) { described_class.new(session_id, email) }

  subject { job.perform_now }

  describe '#perform' do
    let(:url_regex) do
      %r{\Ahttps://api\.crisp\.chat/v1/website/#{ENV['CRISP_WEBSITE_ID']}/people/data/.*\z}
    end

    before do
      stub_request(:patch, url_regex).and_return(body: {
        error: false, reason: "updated", data: {},
      }.to_json)
    end

    context "when email is provided" do
      let(:email) { user.email }

      it 'updates people data' do
        subject

        expect(a_request(:patch, url_regex).with(headers: {
          'X-Crisp-Tier' => 'plugin',
          'Authorization' => /Basic /,
        }, body: /Manager.+#{user.id}/)).to have_been_made.once
      end
    end

    context "when email is not provided, get it from session by API" do
      let(:email) { nil }
      before do
        stub_request(:get, %r{^https://api.crisp.chat/v1/website/#{ENV['CRISP_WEBSITE_ID']}/conversation/.+/meta$})
          .and_return(
            body: { "error" => false, "reason" => "resolved", "data" => { "email" => user.email } }.to_json
          )
      end

      it 'updates people data' do
        subject

        expect(a_request(:patch, url_regex).with(headers: {
          'X-Crisp-Tier' => 'plugin',
          'Authorization' => /Basic /,
        }, body: /Manager.+#{user.id}/)).to have_been_made.once
      end
    end

    context "when email does not exist" do
      let(:email) { "unknown@email.dev" }

      it 'ignore silently' do
        expect { subject }.not_to have_enqueued_job
      end
    end
  end
end
