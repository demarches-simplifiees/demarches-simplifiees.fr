require 'spec_helper'

describe Pipedrive::DealAdapter do
  let(:url) { PIPEDRIVE_API_URL }
  let(:status) { 200 }
  let(:body) { '{}' }

  before do
    stub_request(:get, url)
      .to_return(status: status, body: body)
  end

  describe ".get_deals_ids_for_person" do
    let(:url) { %r{/persons/1/deals\?*} }
    subject { Pipedrive::DealAdapter.get_deals_ids_for_person('1') }

    context "with valid data" do
      let(:body) { '{ "success": true, "data": [ { "id": 34 }, { "id": 35 } ] }' }
      it { is_expected.to eq [34, 35] }
    end

    context "when no data are returned" do
      let(:body) { '{ "success": true, "data": null }' }
      it { is_expected.to eq [] }
    end
  end
end
