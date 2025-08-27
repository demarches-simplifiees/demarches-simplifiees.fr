# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CrispUpdatePeopleDataJob, type: :job do
  let(:user) { users(:default_user) }
  let(:job) { described_class.new(user) }

  subject { job.perform_now }

  describe '#perform' do
    let(:url_regex) do
      %r{\Ahttps://api\.crisp\.chat/v1/website/#{ENV['CRISP_WEBSITE_ID']}/people/data/.*\z}
    end

    before do
      stub_request(:patch, url_regex).and_return(body: {
        error: false, reason: "updated", data: {}
      }.to_json)
    end

    it 'updates people data' do
      subject

      expect(a_request(:patch, url_regex).with(headers: {
        'X-Crisp-Tier' => 'plugin',
        'Authorization' => /Basic /
      }, body: /Manager/)).to have_been_made.once
    end
  end
end
